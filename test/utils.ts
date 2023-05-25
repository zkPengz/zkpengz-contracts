import {ethers} from 'hardhat';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';
import {StandardMerkleTree} from "@openzeppelin/merkle-tree";
import {Erc20, Erc20Test__factory, Pengz, Pengz__factory} from "../typechain";
import {BigNumber, BigNumberish, Event, Signer, utils} from "ethers";
import layers from '../assets/layers.json';
import {readFileSync} from 'fs';
// import tiers from '../assets/tiers.json';
// const {MerkleTree} = require("merkletreejs");
// const {keccak256} = ethers.utils;


const fs = require("fs");

export type Attribute = {
    layer_type: string
    value: string
}

export type MintResult = {
    id: number
    error?: string
}

export type Meta = {
    name: string
    description: string
    image: string
    attributes: Array<Attribute>
}

export type TestSigners = {
    deployer: SignerWithAddress;
    account0: SignerWithAddress;
    account1: SignerWithAddress;
    account2: SignerWithAddress;
};

export const prepareMerkleRoot = (whitelisted: string[]) => {
    const list = whitelisted.map(wl => [wl])
    const tree = StandardMerkleTree.of(list, ["address"]);
    return tree.root
}

export const prepareMerkleProof = (whitelisted: string[], address: string) => {
    const list = whitelisted.map(wl => [wl])
    const tree = StandardMerkleTree.of(list, ["address"]);

    let number = 0
    for (const [i, v] of tree.entries()) {
        if (v[0] === address) {
            number = i
        }
    }

    return tree.getProof(number)
}

export const getSigners = async (): Promise<TestSigners> => {
    const [deployer, account0, account1, account2] = await ethers.getSigners();
    return {
        deployer,
        account0,
        account1,
        account2,
    };
};

export const getMetaAndSaveImage = async (id: any, data: string, save: boolean): Promise<Meta> => {
    const obj = JSON.parse(Buffer
        .from(data.replace('data:application/json;base64,', ''), 'base64')
        .toString())

    const image = Buffer
        .from(obj.image.replace('data:image/svg+xml;base64,', ''), 'base64')
        .toString()

    if (save)
        await fs.promises.writeFile(__dirname + `/artifacts/img_${id}.svg`, image, {
            encoding: 'utf8'
        })

    return obj
}

export const deployErc20 = async (deployer?: SignerWithAddress): Promise<Erc20> => {
    const erc20factory = new Erc20Test__factory(deployer || (await getSigners()).deployer);
    return erc20factory.deploy()
}

export const deployPengz = async (deployer?: SignerWithAddress): Promise<Pengz> => {
    const factory = new Pengz__factory(deployer || (await getSigners()).deployer);

    return factory.deploy(
        1000,
        10,
        10,
        10,
        "50000000000000000",
        "TestContract",
        "TC",
    );
};

export const uploadParams = async (pengz: Pengz) => {
    const colors = readFileSync(__dirname + '/../assets/colors.txt', 'utf-8');
    await pengz.setColors(colors)
    for (const el of layers) {
        const id = el['id']
        const data = el['data']
        await pengz.addLayerType(id, data);
    }
    // for (let i = 0; i < tiers.length; i++) {
    //     await pengz.addTiers(i, tiers[i]);
    // }
}

export const flipState = async (pengz: Pengz) => {
    const tx = await pengz.setSaleStatePublic(true)
    const rc = await tx.wait();

    // @ts-ignore
    const event = rc.events[0]
    const state = ethers.utils.defaultAbiCoder.decode(
        ['bool'],
        utils.hexDataSlice(event.data, 0)
    )

    return state[0]
}

export const flipStateWl = async (pengz: Pengz) => {
    const tx = await pengz.setSaleStateWl(true)
    const rc = await tx.wait();

    // @ts-ignore
    const event = rc.events[0]
    const state = ethers.utils.defaultAbiCoder.decode(
        ['bool'],
        utils.hexDataSlice(event.data, 0)
    )

    return state[0]
}

export const freeze = async (pengz: Pengz) => {
    const tx = await pengz.freezMint()
    const rc = await tx.wait();

    // @ts-ignore
    const event = rc.events[0]
    const state = ethers.utils.defaultAbiCoder.decode(
        ['bool'],
        utils.hexDataSlice(event.data, 0)
    )

    return state[0]
}

export const mintEth = async (pengz: Pengz, count: number, price: BigNumber): Promise<MintResult> => {
    const result: MintResult = {id: -1}
    try {
        const tx = await pengz.mintPublic(count, {
            value: price,
            gasLimit: 2000000 * count
        });
        const rc = await tx.wait()
        let event

        const events: Array<Event> | undefined = rc.events
        if (events) {
            event = events.find(e => e.event === "MintedHash")
        }
        if (event)
            result.id = ethers.utils.defaultAbiCoder.decode(
                ['uint', 'uint'],
                // @ts-ignore
                event.data
            )[0].toNumber()

    } catch (e) {
        result.error = (<Error>e).message
    }

    return result
}

export const mintDev = async (pengz: Pengz, addresses: string[], amount: BigNumberish[]): Promise<MintResult> => {
    const result: MintResult = {id: -1}
    try {
        const tx = await pengz.devMint(addresses, amount, {
            gasLimit: 10000000
        });
        await tx.wait()
    } catch (e) {
        result.error = (<Error>e).message
    }

    return result
}

export const mintWl = async (pengz: Pengz, count: number, price: BigNumber, addresses: string[], signer: SignerWithAddress): Promise<MintResult> => {
    const result: MintResult = {id: -1}
    try {
        const tx = await pengz.connect(signer).mintWl(count, prepareMerkleProof(addresses, signer.address), {
            value: price,
            gasLimit: 1000000 * count,
            from: signer.address,
        });
        const rc = await tx.wait()
        let event

        const events: Array<Event> | undefined = rc.events
        if (events) {
            event = events.find(e => e.event === "MintedHash")
        }
        if (event)
            result.id = ethers.utils.defaultAbiCoder.decode(
                ['uint', 'uint'],
                // @ts-ignore
                event.data
            )[0].toNumber()

    } catch (e) {
        result.error = (<Error>e).message
    }

    return result
}

export const mintAlpha = async (pengz: Pengz, count: number, addresses: string[], signer: SignerWithAddress): Promise<MintResult> => {
    const result: MintResult = {id: -1}
    try {
        const tx = await pengz.connect(signer).mintAlpha(count, prepareMerkleProof(addresses, signer.address), {
            gasLimit: 1000000 * count,
            from: signer.address
        });
        const rc = await tx.wait()
        let event

        const events: Array<Event> = rc.events
        if (events) {
            event = events.find(e => e.event === "MintedHash")
        }
        if (event)
            result.id = ethers.utils.defaultAbiCoder.decode(
                ['uint', 'uint'],
                // @ts-ignore
                event.data
            )[0].toNumber()

    } catch (e) {
        result.error = (<Error>e).message
    }

    return result
}