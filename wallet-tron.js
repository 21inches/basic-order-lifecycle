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


    async send({ to, value, data }) {
        const sender = await this.getAddress();
        const contractAddress = this.tronWeb.address.fromHex(to);

        console.log(`Sending Tron Tx to: ${contractAddress}`);
        console.log(`Value: ${value}`);
        console.log(`data: ${data}`);
        console.log("-----------------------------------------------------");


        let unsignedTx;
        if (data) {
            unsignedTx = await this.tronWeb.transactionBuilder.triggerSmartContract(
                contractAddress,
                "0xca218276",
                {
                    callValue: Number(value),  // amount of TRX to send
                    data: data.replace(/^0x/, ''),
                    feeLimit: 500_000_000,  // 500 TRX; increased for complex operations
                },
            );

            if (!unsignedTx || !unsignedTx.transaction) {
                throw new Error('Contract call failed to build transaction');
            }

            unsignedTx = unsignedTx.transaction;
        } else {
            // Native TRX transfer
            const toBase64 = this.tronWeb.address.toHex(to);
            unsignedTx = await this.tronWeb.transactionBuilder.sendTrx(
                toBase64,
                Number(value),
                sender
            );
        }

        const signedTx = await this.tronWeb.trx.sign(unsignedTx);
        const result = await this.tronWeb.trx.sendRawTransaction(signedTx);

        if (!result.result) {
            throw new Error(`Transaction failed to broadcast: ${JSON.stringify(result)}`);
        }

        const txHash = signedTx.txID;

        // Wait for confirmation
        let receipt = null;
        for (let i = 0; i < 30; i++) { // Increased retry attempts
            try {
                receipt = await this.tronWeb.trx.getTransactionInfo(txHash);
                console.log(`Attempt ${i + 1}: Transaction status:`, receipt?.receipt?.result || 'PENDING');
                if (receipt && receipt.receipt && receipt.receipt.result === 'SUCCESS') break;
                if (receipt && receipt.receipt && receipt.receipt.result === 'FAILED') {
                    console.log("Transaction failed:", receipt);
                    throw new Error(`Transaction failed: ${JSON.stringify(receipt)}`);
                }
            } catch (error) {
                console.log(`Attempt ${i + 1}: Error checking transaction:`, error.message);
            }
            await new Promise((r) => setTimeout(r, 2000)); // Increased wait time
        }

        if (!receipt || !receipt.receipt || receipt.receipt.result !== 'SUCCESS') {
            console.log("Transaction Hash:", txHash);
            console.log("Final receipt:", receipt);
            throw new Error('Transaction failed or not confirmed within timeout.');
        }

        return {
            txHash,
            blockHash: receipt.blockHash,
            blockTimestamp: BigInt(receipt.blockTimeStamp),
        };
    }
}

module.exports = { TronWallet };