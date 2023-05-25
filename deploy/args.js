const ethers = require("ethers");
const _maxSupply = 3333;
const _maxPerWalletPublic = 10;
const _maxPerWalletWl = 2;
const _maxPerTx = 2;
const _price = ethers.utils.parseEther("0.005");
const initialName = "ZKPENGZ";
const initialSymbol = "PENG";

module.exports = [
    _maxSupply,
    _maxPerWalletPublic,
    _maxPerWalletWl,
    _maxPerTx,
    _price,
    initialName,
    initialSymbol
];