const { AbiCoder, Contract, Wallet: PKWallet } = require("ethers");
const ERC20 = require("./IERC20.json");

const coder = AbiCoder.defaultAbiCoder();

class Wallet {
  provider;
  signer;

  constructor(privateKeyOrSigner, provider) {
    this.provider = provider;
    this.signer =
      typeof privateKeyOrSigner === "string"
        ? new PKWallet(privateKeyOrSigner, this.provider)
        : privateKeyOrSigner;
  }

  static async fromAddress(address, provider) {
    await provider.send("anvil_impersonateAccount", [address.toString()]);

    const signer = await provider.getSigner(address.toString());

    return new Wallet(signer, provider);
  }

  async tokenBalance(token) {
    const tokenContract = new Contract(
      token.toString(),
      ERC20.abi,
      this.provider
    );

    return tokenContract.balanceOf(await this.getAddress());
  }

  async topUpFromDonor(token, donor, amount) {
    const donorWallet = await Wallet.fromAddress(donor, this.provider);
    await donorWallet.transferToken(token, await this.getAddress(), amount);
  }

  async getAddress() {
    return this.signer.getAddress();
  }

  async unlimitedApprove(tokenAddress, spender) {
    const currentApprove = await this.getAllowance(tokenAddress, spender);

    // for usdt like tokens
    if (currentApprove !== 0n) {
      await this.approveToken(tokenAddress, spender, 0n);
    }

    await this.approveToken(tokenAddress, spender, (1n << 256n) - 1n);
  }

  async getAllowance(token, spender) {
    const contract = new Contract(token.toString(), ERC20.abi, this.provider);

    return contract.allowance(await this.getAddress(), spender.toString());
  }

  async transfer(dest, amount) {
    await this.signer.sendTransaction({
      to: dest,
      value: amount,
    });
  }

  async transferToken(token, dest, amount) {
    const tx = await this.signer.sendTransaction({
      to: token.toString(),
      data:
        "0xa9059cbb" +
        coder
          .encode(["address", "uint256"], [dest.toString(), amount])
          .slice(2),
    });

    await tx.wait();
  }

  async approveToken(token, spender, amount) {
    const tx = await this.signer.sendTransaction({
      to: token.toString(),
      data:
        "0x095ea7b3" +
        coder
          .encode(["address", "uint256"], [spender.toString(), amount])
          .slice(2),
    });

    await tx.wait();
  }

  async signOrder(srcChainId, order) {
    const typedData = order.getTypedData(srcChainId);
    const domain = {
      name: "1inch Limit Order Protocol",
      version: "4",
      chainId: srcChainId,
      verifyingContract: "0x0656e98bf5b9457048b8ac0985cb48b1b6def4ac", // LOP on Nile
    };

    return this.signer.signTypedData(
      domain,
      { Order: typedData.types[typedData.primaryType] },
      typedData.message
    );
  }

  async send(param) {
    const res = await this.signer.sendTransaction({
      ...param,
      gasLimit: 10_000_000,
      from: this.getAddress(),
    });
    const receipt = await res.wait(1);

    if (receipt && receipt.status) {
      return {
        txHash: receipt.hash,
        blockTimestamp: BigInt((await res.getBlock()).timestamp),
        blockHash: res.blockHash,
      };
    }

    throw new Error((await receipt?.getResult()) || "unknown error");
  }
}

module.exports = { Wallet };
