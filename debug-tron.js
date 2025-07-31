const dotenv = require("dotenv");
dotenv.config();

const Sdk = require("@1inch/cross-chain-sdk");
const { parseEther, parseUnits } = require("ethers");
const { UINT_40_MAX } = require("@1inch/byte-utils");
const { TronWallet } = require("./wallet-tron.js");
const { Resolver } = require("./resolver.js");
const { JsonRpcProvider } = require("ethers");
const { config } = require("./config-tron.js");
const { Address } = Sdk;
const { TronWeb } = require('tronweb');
const { tronAddressToHex, hexAddressToTron } = require('./tron-utils.js');

const tronWeb = new TronWeb({
  fullHost: 'https://nile.trongrid.io',
  headers: { "TRON-PRO-API-KEY": process.env.TRONGRID_API_KEY},
});

async function createOrder(
  escrowFactoryAddress,
  srcChainUserAddress,
  makingAmount,
  takingAmount,
  srcTokenAddress,
  dstTokenAddress,
  secret,
  srcChainId,
  dstChainId,
  resolverAddress,
  srcTimestamp
) {
  if (srcChainId == 728126428 || srcChainId == 3448148188) { // TRON & NILE
    srcChainUserAddress = tronAddressToHex(srcChainUserAddress)
  }

  const order = Sdk.CrossChainOrder.new(
    new Address(escrowFactoryAddress),
    {
      salt: Sdk.randBigInt(1000n),
      maker: new Address(srcChainUserAddress),
      makingAmount,
      takingAmount,
      makerAsset: new Address(srcTokenAddress),
      takerAsset: new Address(dstTokenAddress),
    },
    {
      hashLock: Sdk.HashLock.forSingleFill(secret),
      timeLocks: Sdk.TimeLocks.new({
        srcWithdrawal: 10n, // 10sec finality lock for test
        srcPublicWithdrawal: 120n, // 2m for private withdrawal
        srcCancellation: 121n, // 1sec public withdrawal
        srcPublicCancellation: 122n, // 1sec private cancellation
        dstWithdrawal: 10n, // 10sec finality lock for test
        dstPublicWithdrawal: 100n, // 100sec private withdrawal
        dstCancellation: 101n, // 1sec public withdrawal
      }),
      srcChainId,
      dstChainId,
      srcSafetyDeposit: parseUnits("0.001", 6),
      dstSafetyDeposit: parseUnits("0.001", 6),
    },
    {
      auction: new Sdk.AuctionDetails({
        initialRateBump: 0,
        points: [],
        duration: 120n,
        startTime: srcTimestamp,
      }),
      whitelist: [
        {
          address: new Address(resolverAddress),
          allowFrom: 0n,
        },
      ],
      resolvingStartTime: 0n,
    },
    {
      nonce: Sdk.randBigInt(UINT_40_MAX),
      allowPartialFills: false,
      allowMultipleFills: false,
    }
  );

  return order;
}

async function main() {
  console.log("=== TRON ORDER DEBUG ===");
  
  // create src and dst chain users
  const srcChainUser = new TronWallet(
    config.src.UserPrivateKey,
    tronWeb
  );
  const srcChainResolver = new TronWallet(
    config.src.ResolverPrivateKey,
    tronWeb
  );

  console.log("User address:", await srcChainUser.getAddress());
  console.log("Resolver address:", await srcChainResolver.getAddress());

  // create order
  console.log("\n=== Creating order... ===");
  const makingAmount = parseUnits("0.001", 6);
  const takingAmount = parseUnits("0.001", 6);
  const secret = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const srcTimestamp = BigInt(Math.floor(Date.now() / 1000));
  
  const order = await createOrder(
    config.src.EscrowFactory,
    await srcChainUser.getAddress(),
    makingAmount,
    takingAmount,
    config.src.USDT,
    config.src.TrueERC20,
    secret,
    config.src.ChainId,
    config.dst.ChainId,
    config.src.ResolverContractAddress,
    srcTimestamp
  );
  
  console.log("Order created:", order.build());
  console.log("Order hash:", order.hash());

  // sign order
  console.log("\n=== Signing order... ===");
  const signature = await srcChainUser.signOrder(config.src.ChainId, order);
  console.log("Signature:", signature);

  // Verify signature
  console.log("\n=== Verifying signature... ===");
  const { ethers } = require("ethers");
  const typedData = order.getTypedData(config.src.ChainId);
  const domain = {
    name: '1inch Limit Order Protocol',
    version: '4',
    chainId: config.src.ChainId,
    verifyingContract: config.src.LOP
  };
  
  const hash = ethers.TypedDataEncoder.hash(domain, {
    Order: typedData.types[typedData.primaryType],
  }, typedData.message);
  
  console.log("Order hash for verification:", hash);
  console.log("Signer address:", await srcChainUser.getAddress());
  
  // Try to recover the signer
  try {
    const recoveredAddress = ethers.verifyTypedData(domain, {
      Order: typedData.types[typedData.primaryType],
    }, typedData.message, signature);
    console.log("Recovered signer:", recoveredAddress);
    console.log("Signature valid:", recoveredAddress.toLowerCase() === (await srcChainUser.getAddress()).toLowerCase());
  } catch (error) {
    console.log("Signature verification failed:", error.message);
  }

  // Prepare resolver call
  console.log("\n=== Preparing resolver call... ===");
  const resolverContract = new Resolver(
    config.src.ResolverContractAddress,
    config.dst.ResolverContractAddress
  );
  
  const fillAmount = order.makingAmount;
  const takerTraits = Sdk.TakerTraits.default()
    .setExtension(order.extension)
    .setAmountMode(Sdk.AmountMode.maker)
    .setAmountThreshold(order.takingAmount);
  
  const deployData = resolverContract.deploySrc(
    config.src.ChainId,
    order,
    signature,
    takerTraits,
    fillAmount
  );
  
  console.log("Deploy data:", deployData);
  console.log("Data length:", deployData.data.length);
  
  // Check if we have enough balance
  console.log("\n=== Checking balances... ===");
  try {
    const balance = await tronWeb.trx.getBalance(await srcChainResolver.getAddress());
    console.log("Resolver TRX balance:", balance / 1_000_000, "TRX");
    console.log("Required value:", deployData.value.toString());
    console.log("Has enough balance:", balance >= deployData.value);
  } catch (error) {
    console.log("Error checking balance:", error.message);
  }
}

main().catch(console.error); 