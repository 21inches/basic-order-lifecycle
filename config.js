const dotenv = require("dotenv");
dotenv.config();

const config = {
  ethereumSepolia: {
    LOP: "0x32a209c3736c5bd52e395eabc86b9bca4f602985",
    EscrowFactory: "0x61a32a9263c6ff568c66799a94f8fe09c1db7a66",
    ResolverContractAddress: "0xe002e8e986fd4bbff58b49423c7f7e0e0e92cc59",
    BLT: "0x0BF8E91b08b242cD7380bC92385C90c8270b37f0",
    EscrowSrcImplementationAddress:
      "0xa17ddb01f03a42e0070a0e25099cf3d27b705fff",
    EscrowDstImplementationAddress:
      "0x7490329e69ab8e298a32dc59493034e4d02a5ccf",
    TrueERC20: "0x6dFe5DA3C989aB142CfB16a8FfA2B0e640b1d821",
    ChainId: 11155111,
    UserPrivateKey: process.env.SRC_USER_PRIVATE_KEY,
    RpcUrl: "https://ethereum-sepolia-rpc.publicnode.com",
    ResolverPrivateKey: process.env.SRC_RESOLVER_PRIVATE_KEY,
  },
  baseSepolia: {
    LOP: "0xe30f9abbadc1eb84b41d41035b2a2c7d0bd5f9b2",
    EscrowFactory: "0x178ddaca4499a89e40826ec247baf608051edf9e",
    ResolverContractAddress: "0x3fe279B56F330304446522F04907fBBe03Fe236a",
    BLT: "0xbb7f72d58f5F7147CBa030Ba4c46a94a07E4c2CA",
    EscrowSrcImplementationAddress:
      "0xe55061a78bf30e7f38410b90a6a167d5621cc068",
    EscrowDstImplementationAddress:
      "0x0418b6e80a602474fbfadc3a2594413fe68496bb",
    TrueERC20: "0x8bD9f7C82eBF9D9C830a76bAcb0E99A52163B304",
    ChainId: 84532,
    UserPrivateKey: process.env.DST_USER_PRIVATE_KEY,
    RpcUrl: "https://base-sepolia-rpc.publicnode.com",
    ResolverPrivateKey: process.env.DST_RESOLVER_PRIVATE_KEY,
  },
  etherlinkGhostnet: {
    LOP: "0x60c13fAcC3d2363fa4c1D4c8A0456a4FeBc98903",
    EscrowFactory: "0xE4F87948Efd25651CA20d8b0d750d94612f3FCB7",
    ResolverContractAddress: "0x3e546A14BE5AA04e10Ee050498eaaA4b624FcDAA",
    BLT: "0xb84b2c6c0d554263Eab9f56DEeA8523347270A11",
    EscrowSrcImplementationAddress:
      "0x056e0bb2acb8848be78f1375859f30408a89c005",
    EscrowDstImplementationAddress:
      "0x3b31719534a6a89403b66cb5fdc06320a0dd1604",
    TrueERC20: "0x8382515C25930D298e3B64Eb397005f9Ae71fc0C",
    ChainId: 128123,
    UserPrivateKey: process.env.DST_USER_PRIVATE_KEY,
    RpcUrl: "https://rpc.ankr.com/etherlink_testnet",
    ResolverPrivateKey: process.env.DST_RESOLVER_PRIVATE_KEY,
  },
};

module.exports = { config };
