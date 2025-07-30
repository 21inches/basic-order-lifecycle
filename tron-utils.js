const {TronWeb} = require('tronweb');
const tronWeb = new TronWeb({
    fullHost: 'https://api.trongrid.io',
});

function tronAddressToHex(base58Address) {
    if (!tronWeb.isAddress(base58Address)) {
        throw new Error('Invalid Tron Base58 address provided.');
    }
    const hex = tronWeb.address.toHex(base58Address);
    return `0x${hex.slice(2)}`;
}

function hexAddressToTron(hexAddress) {
    if (typeof hexAddress !== 'string' || !hexAddress.startsWith('0x')) {
        throw new Error('Invalid hexadecimal address provided; it must be a string starting with "0x".');
    }
    return tronWeb.address.fromHex(hexAddress);
}

module.exports = {
    tronAddressToHex,
    hexAddressToTron,
};