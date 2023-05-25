import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {deployPengz, mintDev, flipState, mintEth, uploadParams} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {utils} from "ethers";

chai.use(solidity);
const {expect} = chai;

describe('Dev', () => {

    if (!["hardhat", "localhost"].includes(network.name))
        return

    let pengz: Pengz;
    let deployer: SignerWithAddress;
    let snapshotId: number;

    before(async () => {
        [deployer] = await ethers.getSigners();
        pengz = await deployPengz();
        await uploadParams(pengz);
        await flipState(pengz);
    });

    beforeEach(async () => {
        snapshotId = await ethers.provider.send('evm_snapshot', []);
    });

    afterEach(async () => {
        await ethers.provider.send('evm_revert', [snapshotId]);
    });

    it('should mint by dev free', async () => {
        const [owner, wallet1, wallet2] = await ethers.getSigners();
        const price = utils.parseEther("0.05")

        await mintEth(pengz, 1, price)

        expect((await pengz.balanceOf(owner.address)).toNumber()).to.eq(1)
        expect((await pengz.balanceOf(wallet1.address)).toNumber()).to.eq(0)
        expect((await pengz.balanceOf(wallet2.address)).toNumber()).to.eq(0)

        await mintDev(pengz, [wallet1.address, wallet2.address], [2, 4])
        expect((await pengz.balanceOf(owner.address)).toNumber()).to.eq(1)
        expect((await pengz.balanceOf(wallet1.address)).toNumber()).to.eq(2)
        expect((await pengz.balanceOf(wallet2.address)).toNumber()).to.eq(4)

        let resp
        resp = (await mintDev(pengz, [wallet1.address, wallet2.address], [2, 4, 5])).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'MismatchingLengths()'")
    });

})
