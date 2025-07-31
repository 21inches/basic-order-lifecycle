const { Interface } = require("ethers");


// Resolver ABI
let abi = require("./Resolver.json").abi;
let iface = new Interface(abi);
let deploySrcFunction = iface.getFunction("deploySrc");
let functionSig = deploySrcFunction.selector;
console.log(`The function signature for deploySrc is: ${functionSig}`);