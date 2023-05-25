import {task, types} from 'hardhat/config';
import {utils} from "ethers";

task('simple-mint', 'Mint simple random peng')
    .addOptionalParam(
        'address',
        'The `Pengz` contract address',
        '0x5FbDB2315678afecb367f032d93F642f64180aa3',
        types.string,
    )
    .setAction(async ({address}, {ethers}) => {
        const nftFactory = await ethers.getContractFactory('Pengz');
        const nftContract = nftFactory.attach(address);
        const price = utils.parseEther('0.05')

        const tx = await nftContract.mintEth(1, {
            value: price
        });
        const rc = await tx.wait()
        const state = ethers.utils.defaultAbiCoder.decode(
            ['uint', 'string'],
            rc.events?.[1].data
        )
        const id = state[0].toNumber()
        const uri = await nftContract.tokenURI(id)
        console.log(`Minted new token: id=${state[0].toNumber()}, hash=${state[1]}\nuri: ${uri}`)
    });