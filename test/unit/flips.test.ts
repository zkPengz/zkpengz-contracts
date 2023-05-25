import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {deployPengz, flipState} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);
const {expect} = chai;

describe('Flips', () => {

    if (!["hardhat", "localhost"].includes(network.name))
        return

    let pengz: Pengz;
    let deployer: SignerWithAddress;
    let snapshotId: number;

    before(async () => {
        [deployer] = await ethers.getSigners();
        pengz = await deployPengz();
    });

    beforeEach(async () => {
        snapshotId = await ethers.provider.send('evm_snapshot', []);
    });

    afterEach(async () => {
        await ethers.provider.send('evm_revert', [snapshotId]);
    });

    it('should flip sale state', async () => {
        expect(await flipState(pengz)).to.be.true;
    });

})
