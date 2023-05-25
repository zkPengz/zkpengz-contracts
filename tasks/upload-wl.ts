import {task, types} from 'hardhat/config';
const { MerkleTree } = require("merkletreejs");
const { keccak256 } = ethers.utils;

task('upload-wl', 'Upload whitelisted wallets')
    .addOptionalParam(
        'address',
        'The `Pengz` contract address',
        '0x5FbDB2315678afecb367f032d93F642f64180aa3',
        types.string,
    )
    .setAction(async ({address}, {ethers}) => {
        const nftFactory = await ethers.getContractFactory('Pengz');
        const nftContract = nftFactory.attach(address);

        const whitelisted = [];

        const padBuffer = (addr) => {
            return Buffer.from(addr.substr(2).padStart(32 * 2, 0), "hex");
        };

        const leaves = whitelisted.map((address) => padBuffer(address));
        const tree = new MerkleTree(leaves, keccak256, {sort: true});

        const merkleRoot = tree.getHexRoot();
        await nftContract.setMerkleRootWl(merkleRoot)
    });