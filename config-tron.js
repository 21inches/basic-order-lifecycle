const dotenv = require("dotenv");
dotenv.config();

const config = {
    src: {
        LOP: "0x0656e98bf5b9457048b8ac0985cb48b1b6def4ac", // "TAYjAyuKjKvkhkcvgJ7CgrJ8PVziU5vr4R",
        EscrowFactory: "0x4fb1926857ec058d3c6f659a376dede5bd41583f", // "THEb78FZnopZYvKpJvRcmicZLcewdmxURR",
        ResolverContractAddress: "0xd84b5640181b78193c5f532dc9e03a760401845b", // "TVgsCzfX9t42kchuoQEjKkqUPDt92ZwsPh",
        USDT: "0xeca9bc828a3005b9a3b909f2cc5c2a54794de05f", //"TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf",
        EscrowSrcImplementationAddress: "0x0bc4bf8569dbbcb793788db183c7dbb4d0b2f80d", // "TB3S8U9PN4TkR4ntfcoNoZDjKiWNgZax7L",
        EscrowDstImplementationAddress: "0xdd69f5e6be02175b3953de663729b1238ff5f03c", // "TW9wGipDxFLXvqHxBn3euBY3fWBqvExA6t",
        TrueERC20: "0xf8dfdf1ab75de04f485a9871d9298a070b9bebc6", // "TYf8mVp2tC7K9AYbFFfv8gVH82JEkbKKDj",
        ChainId: 1001,
        UserPrivateKey: process.env.TRON_SRC_USER_PRIVATE_KEY,
        RpcUrl: "https://nile.trongrid.io/jsonrpc",
        ResolverPrivateKey: process.env.TRON_SRC_RESOLVER_PRIVATE_KEY,
    },
    dst: {
        LOP: "0xe30f9abbadc1eb84b41d41035b2a2c7d0bd5f9b2",
        EscrowFactory: "0x178ddaca4499a89e40826ec247baf608051edf9e",
        ResolverContractAddress: "0x3fe279B56F330304446522F04907fBBe03Fe236a",
        BLT: "0xbb7f72d58f5F7147CBa030Ba4c46a94a07E4c2CA",
        EscrowSrcImplementationAddress: "0xe55061a78bf30e7f38410b90a6a167d5621cc068",
        EscrowDstImplementationAddress: "0x0418b6e80a602474fbfadc3a2594413fe68496bb",
        TrueERC20: "0x8bD9f7C82eBF9D9C830a76bAcb0E99A52163B304",
        ChainId: 84532,
        UserPrivateKey: process.env.DST_USER_PRIVATE_KEY,
        RpcUrl: "https://base-sepolia.drpc.org",
        ResolverPrivateKey: process.env.DST_RESOLVER_PRIVATE_KEY,
    },
};

module.exports = {config};
