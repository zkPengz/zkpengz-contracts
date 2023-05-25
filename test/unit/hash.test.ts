import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {deployPengz} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {utils} from "ethers";

chai.use(solidity);
const {expect} = chai;

describe('Hash', () => {

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

    it('should generate valid hash', async () => {
        const tx = await pengz.generateHash();
        const rc = await tx.wait()
        const events = rc.events
        let event
        let gens = []
        if (events && events.length) {
            event = events.find(e => e.event === "NewHash")
        }

        expect(!!event).to.be.true
    });

})
