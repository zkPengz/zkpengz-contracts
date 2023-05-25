import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {deployPengz, flipState, freeze, getMetaAndSaveImage, mintEth, uploadParams} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {utils} from "ethers";

chai.use(solidity);
const {expect} = chai;

describe('Frozen', () => {

    if (!["hardhat", "localhost"].includes(network.name))
        return

    let pengz: Pengz;
    let deployer: SignerWithAddress;
    let snapshotId: number;

    before(async () => {
        [deployer] = await ethers.getSigners();
        pengz = await deployPengz();
        await uploadParams(pengz);
        await flipState(pengz)
    });

    beforeEach(async () => {
        snapshotId = await ethers.provider.send('evm_snapshot', []);
    });

    afterEach(async () => {
        await ethers.provider.send('evm_revert', [snapshotId]);
    });

    it('should mint one token', async () => {
        const price = utils.parseEther("0.05")

        const id = (await mintEth(pengz, 1, price)).id
        expect(id).to.eq(1)

        const uri = await pengz.tokenURI(id)
        const data = await getMetaAndSaveImage(id, uri, true)

        expect(data.name).to.eq('Pengz #' + id)
        expect(data.attributes.length).to.eq(6)
        expect(data.attributes[0].layer_type).to.eq('Background')
    })

    it('should mint after forever frozen', async () => {
        await freeze(pengz)

        const price = utils.parseEther("0.05")

        let resp
        resp = (await mintEth(pengz, 1, price)).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'MintFrozenForever()'")
    }).timeout(20000 * 10)

})
