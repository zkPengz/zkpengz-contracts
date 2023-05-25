<br />
<div align="center">
<img src="https://i.imgur.com/K0Lmx6B.png" alt="Logo" width="225" height="90" style="borderRadius: 20px">

<h3 align="center">
This Repository contains the smart contracts of the <a href="https://zkpengz.com" target="_blank">zkPengz NFT Collection</a>.
<br>The FIRST fully #onchain NFT collection on <a href="https://twitter.com/zksync" target="_blank">@zksync</a>.
 ERA
</h3>
<br />
</div>

<p align="center">
        <a href="https://discord.gg/6RF98VGjjd" target="_blank">
            <img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white"/>
        </a>
        <a href="https://twitter.com/zkPengz" target="_blank">
            <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white"/>
        </a>
    </p>

## Contracts overview
* [ZKPENGZ.sol](/contracts/ZKPENGZ.sol) - Fully OnChain NFT contract based on [ERC721A](https://github.com/chiru-labs/ERC721A). Mostly consists of code describing on-chain metadata storage/logic.
* [BaseHelper.sol](/contracts/BaseHelper.sol) - Contains some useful functions for the [main](/contracts/ZKPENGZ.sol) contract. 
* [MultisigOwnable.sol](/contracts/MultisigOwnable.sol) - Implementation of [tubby-cats/dual-ownership-nft](https://github.com/tubby-cats/dual-ownership-nft) style ownership.


### ZKPENGZ.sol overview
> As mentioned before, the biggest part of this contract consists of low-level functions capable of storing metadata on-chain and returning metadata to the front-end.

### Storage format
Each layer is stored in a contract in the form of a struct with only two fields: `layerName` and `pixels`.

``` solidity
 struct Layer {
            string layerName;
            string pixels;
    }
``` 
Basically, the `layerName` variable stores the name value of a layer, and the `pixels` variable is capable of representing data about each pixel in the layer.

### Key functions
* [Generates a hash from a tokenId, address, and random number.](/contracts/ZKPENGZ.sol#L389).
* [Generation of a random number for the next minted TokenId](/contracts/ZKPengz.sol#L439).
* [Constructs SVG image of a token from hash](/contracts/ZKPENGZ.sol#L471).
* [Hash Encoding](/contracts/ZKPENGZ.sol#L603).

### Deploy locally
```
npx hardhat deploy-local --network localhost
```
### Deploy to testnet
```
npx hardhat deploy --network zkTestnet
```

# License
Distributed under MIT license.
