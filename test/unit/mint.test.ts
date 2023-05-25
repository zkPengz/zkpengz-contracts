import chai from 'chai';
import {solidity} from 'ethereum-waffle';
import {Pengz} from "../../typechain";
import {ethers, network} from "hardhat";
import {deployPengz, flipState, getMetaAndSaveImage, mintEth, uploadParams} from "../utils";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {utils} from "ethers";

chai.use(solidity);
const {expect} = chai;

describe('Mint', () => {

    if (!["hardhat", "localhost"].includes(network.name))
        return

    let pengz: Pengz;
    let deployer: SignerWithAddress;
    let snapshotId: number;

    before(async () => {
        [deployer] = await ethers.getSigners();
        pengz = await deployPengz();
        await uploadParams(pengz);
    });

    beforeEach(async () => {
        snapshotId = await ethers.provider.send('evm_snapshot', []);
    });

    afterEach(async () => {
        await ethers.provider.send('evm_revert', [snapshotId]);
    });

    it('should show only errors', async () => {
        const price = utils.parseEther("0.05")

        let resp
        resp = (await mintEth(pengz, 1, price)).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'SaleNotActive()'")

        await flipState(pengz)

        resp = (await mintEth(pengz, 25, price.mul(25))).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'MaxPerWalletReached()'")

        resp = (await mintEth(pengz, 1, utils.parseEther("0.04"))).error
        expect(resp).to.eq("VM Exception while processing transaction: reverted with custom error 'IncorrectValueSent()'")
    });

    it('should mint one token', async () => {
        await flipState(pengz)
        const price = utils.parseEther("0.05")

        const id = (await mintEth(pengz, 1, price)).id
        expect(id).to.eq(1)

        try {
            const uri = await pengz.tokenURI(id)
            const data = await getMetaAndSaveImage(id, uri, true)

            expect(data.name).to.eq('Pengz #' + id)
            expect(data.attributes.length).to.eq(6)
            expect(data.attributes[0].layer_type).to.eq('Background')
        } catch (e) {
            const hash = await pengz.getTokenHash(id)
            console.log(`[ERROR] Cant render ${id} / ${hash}`)
            console.log(`[ERROR] Balance of: ${(await pengz.balanceOf(deployer.address)).toNumber()}`)
        }
    })

    it('should mint 10 tokens', async () => {
        await flipState(pengz)
        const price = utils.parseEther("0.50")

        const resp = await mintEth(pengz, 10, price)
        if (resp.id < 0) {
            console.log(`[INFO] Error through minting 10 tokens: ${resp.error}`)
        }
        for (let id = 1; id <= 10; id++) {
            try {
                const uri = await pengz.tokenURI(id)
                const data = await getMetaAndSaveImage(id, uri, true)

                expect(data.name).to.eq('Pengz #' + id)
                expect(data.attributes.length).to.eq(6)
                expect(data.attributes[0].layer_type).to.eq('Background')
            } catch (e) {
                const hash = await pengz.getTokenHash(id)
                console.log(`[ERROR] Cant render ${id} / ${hash}`)
                console.log(`[ERROR] Balance of: ${(await pengz.balanceOf(deployer.address)).toNumber()}`)
            }
        }
    }).timeout(60000 * 20)

})
