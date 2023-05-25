import {task, types} from 'hardhat/config';
import layers from '../assets/layers.json';
import {readFileSync} from "fs";

task('upload-params', 'Upload all layers and parameters')
    .addOptionalParam(
        'address',
        'The `Pengz` contract address',
        '0x5FbDB2315678afecb367f032d93F642f64180aa3',
        types.string,
    )
    .setAction(async ({address}, {ethers}) => {
        const nftFactory = await ethers.getContractFactory('Pengz');
        const nftContract = nftFactory.attach(address);

        const colors = readFileSync(__dirname + '/../assets/colors.txt', 'utf-8');
        await nftContract.setColors(colors)

        for (const el of layers) {
            const id = el['id']
            const data = el['data']
            await nftContract.addLayerType(id, data);
            console.log(`Uploaded layers for type: ${id}`)
        }
    });