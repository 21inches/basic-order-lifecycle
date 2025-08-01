const { ethers } = require('ethers');
const Sdk = require('@1inch/cross-chain-sdk');

/**
 * Simple function to sign an order using an EVM signer
 * @param {string} privateKey - The private key of the signer
 * @param {number} chainId - The chain ID where the order will be used
 * @param {object} orderParams - Parameters to create the order
 * @returns {object} - The signed order and signature
 */
async function signOrder(privateKey, chainId, orderParams = {}) {
  try {
    // Create a wallet from private key
    const wallet = new ethers.Wallet(privateKey);
    console.log("👤 Signer address:", wallet.address);
    
    // Default order parameters
    const defaultParams = {
      escrowFactoryAddress: "0x61a32a9263c6ff568c66799a94f8fe09c1db7a66", // Example factory
      maker: wallet.address,
      makingAmount: ethers.parseEther("0.001"),
      takingAmount: ethers.parseEther("0.001"),
      makerAsset: "0x0BF8E91b08b242cD7380bC92385C90c8270b37f0", // Example token
      takerAsset: "0xbb7f72d58f5F7147CBa030Ba4c46a94a07E4c2CA", // Example token
      secret: "0x0000000000000000000000000000000000000000000000000000000000000000",
      srcChainId: chainId,
      dstChainId: 84532, // Base Sepolia
      resolverAddress: "0xe002e8e986fd4bbff58b49423c7f7e0e0e92cc59", // Example resolver
      srcTimestamp: BigInt(Math.floor(Date.now() / 1000))
    };
    
    // Merge with provided parameters
    const params = { ...defaultParams, ...orderParams };
    
    console.log("📋 Creating order with parameters:");
    console.log("  - Maker:", params.maker);
    console.log("  - Making Amount:", ethers.formatEther(params.makingAmount), "tokens");
    console.log("  - Taking Amount:", ethers.formatEther(params.takingAmount), "tokens");
    console.log("  - Source Chain ID:", params.srcChainId);
    console.log("  - Destination Chain ID:", params.dstChainId);
    
    // Create the order using 1inch SDK
    const order = Sdk.CrossChainOrder.new(
      new Sdk.Address(params.escrowFactoryAddress),
      {
        salt: Sdk.randBigInt(1000n),
        maker: new Sdk.Address(params.maker),
        makingAmount: params.makingAmount,
        takingAmount: params.takingAmount,
        makerAsset: new Sdk.Address(params.makerAsset),
        takerAsset: new Sdk.Address(params.takerAsset),
      },
      {
        hashLock: Sdk.HashLock.forSingleFill(params.secret),
        timeLocks: Sdk.TimeLocks.new({
          srcWithdrawal: 10n, // 10sec finality lock for test
          srcPublicWithdrawal: 120n, // 2m for private withdrawal
          srcCancellation: 121n, // 1sec public withdrawal
          srcPublicCancellation: 122n, // 1sec private cancellation
          dstWithdrawal: 10n, // 10sec finality lock for test
          dstPublicWithdrawal: 100n, // 100sec private withdrawal
          dstCancellation: 101n, // 1sec public withdrawal
        }),
        srcChainId: params.srcChainId,
        dstChainId: params.dstChainId,
        srcSafetyDeposit: ethers.parseEther("0.001"),
        dstSafetyDeposit: ethers.parseEther("0.001"),
      },
      {
        auction: new Sdk.AuctionDetails({
          initialRateBump: 0,
          points: [],
          duration: 120n,
          startTime: params.srcTimestamp,
        }),
        whitelist: [
          {
            address: new Sdk.Address(params.resolverAddress),
            allowFrom: 0n,
          },
        ],
        resolvingStartTime: 0n,
      },
      {
        nonce: Sdk.randBigInt(2n ** 40n - 1n),
        allowPartialFills: false,
        allowMultipleFills: false,
      }
    );
    
    console.log("✅ Order created successfully");
    
    // Get the typed data for signing
    const typedData = order.getTypedData(params.srcChainId);
    const domain = {
      name: "1inch Limit Order Protocol",
      version: "4",
      chainId: params.srcChainId,
      verifyingContract: "0x0656e98bf5b9457048b8ac0985cb48b1b6def4ac", // LOP contract
    };
    
    console.log("🔐 Signing order...");
    
    // Sign the order
    const signature = await wallet.signTypedData(
      domain,
      { Order: typedData.types[typedData.primaryType] },
      typedData.message
    );
    
    console.log("✅ Order signed successfully");
    console.log("📝 Signature:", signature);
    
    // Return the order and signature
    return {
      order: order,
      signature: signature,
      orderData: order.build(),
      typedData: typedData,
      domain: domain
    };
    
  } catch (error) {
    console.error("❌ Error signing order:", error.message);
    throw error;
  }
}

/**
 * Verify a signed order
 * @param {object} order - The order object
 * @param {string} signature - The signature
 * @param {number} chainId - The chain ID
 * @param {string} expectedSigner - The expected signer address
 * @returns {boolean} - True if signature is valid
 */
function verifyOrderSignature(order, signature, chainId, expectedSigner) {
  try {
    const typedData = order.getTypedData(chainId);
    const domain = {
      name: "1inch Limit Order Protocol",
      version: "4",
      chainId: chainId,
      verifyingContract: "0x0656e98bf5b9457048b8ac0985cb48b1b6def4ac",
    };
    
    // Recover the signer from the signature
    const recoveredAddress = ethers.verifyTypedData(
      domain,
      { Order: typedData.types[typedData.primaryType] },
      typedData.message,
      signature
    );
    
    const isValid = recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
    console.log("🔍 Signature verification:", isValid ? "✅ Valid" : "❌ Invalid");
    console.log("  - Expected signer:", expectedSigner);
    console.log("  - Recovered signer:", recoveredAddress);
    
    return isValid;
  } catch (error) {
    console.error("❌ Error verifying signature:", error.message);
    return false;
  }
}

// Example usage
async function example() {
  console.log("🚀 Example: Signing an Order");
  console.log("=" .repeat(50));
  
  // Example private key (replace with your own)
  const privateKey = "0x1234567890123456789012345678901234567890123456789012345678901234";
  
  // Example order parameters
  const orderParams = {
    escrowFactoryAddress: "0x61a32a9263c6ff568c66799a94f8fe09c1db7a66",
    makerAsset: "0x0BF8E91b08b242cD7380bC92385C90c8270b37f0",
    takerAsset: "0xbb7f72d58f5F7147CBa030Ba4c46a94a07E4c2CA",
    makingAmount: ethers.parseEther("0.001"),
    takingAmount: ethers.parseEther("0.001"),
  };
  
  try {
    // Sign the order
    const result = await signOrder(privateKey, 11155111, orderParams); // Sepolia chain ID
    
    console.log("\n📊 Order Details:");
    console.log("  - Order Hash:", result.orderData);
    console.log("  - Signature:", result.signature);
    
    // Verify the signature
    const wallet = new ethers.Wallet(privateKey);
    const isValid = verifyOrderSignature(result.order, result.signature, 11155111, wallet.address);
    
    console.log("\n🎯 Final Result:", isValid ? "✅ Order signed and verified successfully!" : "❌ Verification failed");
    
  } catch (error) {
    console.error("❌ Example failed:", error.message);
  }
}

// Export functions
module.exports = {
  signOrder,
  verifyOrderSignature,
  example
};

// Run example if this file is executed directly
if (require.main === module) {
  example().catch(console.error);
} 