import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {
    deployPengz,
    flipState,
    uploadParams,
    mintWl,
    prepareMerkleRoot, flipStateWl
} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {utils} from "ethers";

chai.use(solidity);
const {expect} = chai;

describe('Wl', () => {

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
        const [owner, wallet1, wallet2, wallet3] = await ethers.getSigners();
        const wlList = [wallet1.address]
        const price = utils.parseEther("0.05")

        await pengz.setMerkleRootWl(prepareMerkleRoot(wlList))

        let resp

        //wl
        resp = (await mintWl(pengz, 1, price, wlList, wallet2)).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'SaleNotActive()'")
        await flipStateWl(pengz)

        resp = (await mintWl(pengz, 1, price, wlList, wallet2)).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'IncorrectMerkleProof()'")

        await mintWl(pengz, 1, price, wlList, wallet1)
        expect((await pengz.balanceOf(wallet1.address)).toNumber()).to.eq(1)
        expect((await pengz.balanceOf(wallet2.address)).toNumber()).to.eq(0)

        resp = (await mintWl(pengz, 1, price, wlList, wallet3)).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'IncorrectMerkleProof()'")
    });

})
