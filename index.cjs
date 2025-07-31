const dotenv = require("dotenv");
dotenv.config();

const Sdk = require("@1inch/cross-chain-sdk");
const { parseEther, parseUnits } = require("ethers");
const { UINT_40_MAX } = require("@1inch/byte-utils");
const { Wallet } = require("./wallet.js");
const { Resolver } = require("./resolver.js");
const { JsonRpcProvider } = require("ethers");
const { config } = require("./config.js");
const { EscrowFactory } = require("./escrow-factory.js");

const { Address } = Sdk;

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
      srcSafetyDeposit: parseEther("0.001"),
      dstSafetyDeposit: parseEther("0.001"),
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
  // create src and dst chain users
  const srcChainUser = new Wallet(
    config.src.UserPrivateKey,
    new JsonRpcProvider(config.src.RpcUrl)
  );
  const srcChainResolver = new Wallet(
    config.src.ResolverPrivateKey,
    new JsonRpcProvider(config.src.RpcUrl)
  );
  const srcEscrowFactory = new EscrowFactory(
    new JsonRpcProvider(config.src.RpcUrl),
    config.src.EscrowFactory
  );

  const dstChainUser = new Wallet(
    config.dst.UserPrivateKey,
    new JsonRpcProvider(config.dst.RpcUrl)
  );
  const dstChainResolver = new Wallet(
    config.dst.ResolverPrivateKey,
    new JsonRpcProvider(config.dst.RpcUrl)
  );
  const dstEscrowFactory = new EscrowFactory(
    new JsonRpcProvider(config.dst.RpcUrl),
    config.dst.EscrowFactory
  );

  // create order
  console.log("Creating order...");
  const makingAmount = parseUnits("0.001", 18);
  const takingAmount = parseUnits("0.001", 18);
  const secret =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  const srcTimestamp = BigInt(Math.floor(Date.now() / 1000));
  const order = await createOrder(
    config.src.EscrowFactory,
    await srcChainUser.getAddress(),
    makingAmount,
    takingAmount,
    config.src.BLT,
    config.dst.BLT,
    secret,
    config.src.ChainId,
    config.dst.ChainId,
    config.src.ResolverContractAddress,
    srcTimestamp
  );
  console.log("Order created", order.build());

  // // sign order
  console.log("Signing order...");
  const signature = await srcChainUser.signOrder(
    config.src.ChainId,
    order,
    config.src.LOP
  );
  console.log("Order signed", signature);

  // fill order
  console.log("Filling order...");
  const resolverContract = new Resolver(
    config.src.ResolverContractAddress,
    config.dst.ResolverContractAddress
  );
  const fillAmount = order.makingAmount;
  const { txHash: orderFillHash, blockHash: srcDeployBlock } =
    await srcChainResolver.send(
      resolverContract.deploySrc(
        config.src.ChainId,
        order,
        signature,
        Sdk.TakerTraits.default()
          .setExtension(order.extension)
          .setAmountMode(Sdk.AmountMode.maker)
          .setAmountThreshold(order.takingAmount),
        fillAmount,
        order.escrowExtension.hashLockInfo,
        config.src.LOP
      )
    );
  console.log("Order filled", orderFillHash);

  console.log("Fetching src escrow event...");
  const srcEscrowEvent = await srcEscrowFactory.getSrcDeployEvent(
    srcDeployBlock
  );
  const dstImmutables = srcEscrowEvent[0]
    .withComplement(srcEscrowEvent[1])
    .withTaker(new Address(resolverContract.dstAddress));
  console.log("Src escrow event fetched");

  console.log("Deploying dst escrow...");
  const { txHash: dstDepositHash, blockTimestamp: dstDeployedAt } =
    await dstChainResolver.send(resolverContract.deployDst(dstImmutables));
  console.log("Dst escrow deployed", dstDepositHash);

  console.log("Getting escrow addresses...");
  const ESCROW_SRC_IMPLEMENTATION = await srcEscrowFactory.getSourceImpl();
  const ESCROW_DST_IMPLEMENTATION = await dstEscrowFactory.getDestinationImpl();
  const srcEscrowAddress = new Sdk.EscrowFactory(
    new Address(config.src.EscrowFactory)
  ).getSrcEscrowAddress(srcEscrowEvent[0], ESCROW_SRC_IMPLEMENTATION);

  const dstEscrowAddress = new Sdk.EscrowFactory(
    new Address(config.dst.EscrowFactory)
  ).getDstEscrowAddress(
    srcEscrowEvent[0],
    srcEscrowEvent[1],
    dstDeployedAt,
    new Address(resolverContract.dstAddress),
    ESCROW_DST_IMPLEMENTATION
  );
  console.log("Escrow addresses fetched");

  console.log("Src escrow address", srcEscrowAddress);
  console.log("Dst escrow address", dstEscrowAddress);

  console.log("Withdrawing from dst escrow for user in 20secs...");
  await new Promise((resolve) => setTimeout(resolve, 20000));
  const { txHash: dstWithdrawHash } = await dstChainResolver.send(
    resolverContract.withdraw(
      "dst",
      dstEscrowAddress,
      secret,
      dstImmutables.withDeployedAt(dstDeployedAt)
    )
  );
  console.log("Dst escrow withdrawn", dstWithdrawHash);

  console.log("Withdrawing from src escrow for resolver...");
  const { txHash: resolverWithdrawHash } = await srcChainResolver.send(
    resolverContract.withdraw(
      "src",
      srcEscrowAddress,
      secret,
      srcEscrowEvent[0]
    )
  );
  console.log("Src escrow withdrawn", resolverWithdrawHash);
}

main();
