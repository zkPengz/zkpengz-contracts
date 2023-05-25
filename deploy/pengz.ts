import {Wallet} from "zksync-web3";
import * as ethers from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {Deployer} from "@matterlabs/hardhat-zksync-deploy";

export default async function (hre: HardhatRuntimeEnvironment) {
    console.log(`Running deploy script`);

    const wallet = new Wallet("...");
    const deployer = new Deployer(hre, wallet);
    const artifact = await deployer.loadArtifact("ZKPENGZ");

    const _maxSupply = 3333;
    const _maxPerWalletPublic = 10;
    const _maxPerWalletWl = 2;
    const _maxPerTx = 2;
    const _price = ethers.utils.parseEther("0.005");
    const initialName = "ZKPENGZ";
    const initialSymbol = "PENG";

    console.log(`Deploying contract...`)
    const Contract = await deployer.deploy(artifact, [
        _maxSupply,
        _maxPerWalletPublic,
        _maxPerWalletWl,
        _maxPerTx,
        _price,
        initialName,
        initialSymbol
    ]);

    const contractAddress = Contract.address;
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`);
}