const ERC20 = require("./IERC20.json");
const { TypedDataEncoder } = require('ethers');

class TronWallet {
    tronWeb;
    privateKey;
    signerAddress;

    constructor(privateKey, tronWebInstance) {
        if (!tronWebInstance) {
            throw new Error("tronWeb instance is required.");
        }
        this.tronWeb = tronWebInstance;
        this.privateKey = privateKey;
        this.tronWeb.setPrivateKey(this.privateKey);
        this.signerAddress = this.tronWeb.address.fromPrivateKey(this.privateKey);
    }

    async getAddress() {
        return this.signerAddress;
    }

    async signOrder(srcChainId, order) {
        const typedData = order.getTypedData(srcChainId);
        const domain = {
            name: '1inch Limit Order Protocol',
            version: '4',
            chainId: srcChainId,
            verifyingContract: "0x0656e98bf5b9457048b8ac0985cb48b1b6def4ac" // LOP on Nile
        };

        const hash = TypedDataEncoder.hash(domain, {
            Order: typedData.types[typedData.primaryType],
        }, typedData.message);

        const hashStripped = hash.replace(/^0x/, '');
        const signature = await this.tronWeb.trx.sign(hashStripped);
        return signature;
    }

    /**
     * Sends a transaction to a smart contract on the Tron network.
     * This version correctly handles pre-encoded data payloads from SDKs.
     * @param {object} param The transaction parameters.
     * @param {string} param.to The contract address (can be hex or Base58).
     * @param {string} param.data The pre-encoded hex data payload (e.g., "0x...").
     * @returns {Promise<{txHash: string}>}
     */
    async send(param) {
        let { to, data } = param;
        let contractAddressInBase58 = to;

        // 1. Convert address if it's in hex format
        if (typeof to === 'string' && to.startsWith('0x')) {
            console.log(`Detected hex address: ${to}. Converting to Tron Base58 format...`);
            contractAddressInBase58 = this.tronWeb.address.fromHex(to);
            console.log(`Converted address: ${contractAddressInBase58}`);
        }

        // 2. Prepare the data payload by removing the '0x' prefix
        const fullDataPayload = data.substring(2);

        console.log(`Sending Tron Tx to: ${contractAddressInBase58}`);

        try {
            // 3. Create a transaction shell.
            // We pass an empty function selector and an empty parameters array `[]`
            // to prevent tronweb from trying to re-encode anything.
            const transaction = await this.tronWeb.transactionBuilder.triggerSmartContract(
                contractAddressInBase58,
                '00000000', // Dummy selector, it will be overwritten.
                {
                    feeLimit: 150_000_000, // Increased fee limit for complex transactions
                    callValue: 0,
                },
                [], // IMPORTANT: Must be an empty array.
                this.signerAddress
            );

            if (!transaction.result || !transaction.result.result) {
                throw new Error(`Failed to create transaction shell: ${JSON.stringify(transaction)}`);
            }

            // 4. Manually overwrite the 'data' field in the transaction object.
            // This is where we inject our correct, pre-encoded payload from the SDK.
            transaction.transaction.raw_data.contract[0].parameter.value.data = fullDataPayload;

            // 5. Sign the correctly-formed transaction.
            const signedTxn = await this.tronWeb.trx.sign(transaction.transaction, this.privateKey);

            // 6. Broadcast the signed transaction.
            const broadcast = await this.tronWeb.trx.sendRawTransaction(signedTxn);

            if (broadcast.result) {
                console.log("Tron transaction broadcast successfully:", broadcast.txid);
                // Add a small delay to allow the node to process the transaction
                await new Promise(resolve => setTimeout(resolve, 3000));
                return { txHash: broadcast.txid };
            } else {
                const broadcastError = broadcast.message ? this.tronWeb.utils.bytes.byte2str(broadcast.message) : JSON.stringify(broadcast);
                throw new Error(`Transaction broadcast failed: ${broadcastError}`);
            }
        } catch (error) {
            console.error("Error sending Tron transaction:", error);
            throw error;
        }
    }
}

module.exports = { TronWallet };