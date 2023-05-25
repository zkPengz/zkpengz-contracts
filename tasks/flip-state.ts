import {task, types} from 'hardhat/config';
import {utils} from 'ethers';

task('flip-state', 'Flip sale state')
    .addOptionalParam(
        'address',
        'The `Pengz` contract address',
        '0x5FbDB2315678afecb367f032d93F642f64180aa3',
        types.string,
    )
    .setAction(async ({address}, {ethers}) => {
        const nftFactory = await ethers.getContractFactory('Pengz');
        const nftContract = nftFactory.attach(address);

        const tx = await nftContract.setSaleState(1)
        const rc = await tx.wait();
        const state = ethers.utils.defaultAbiCoder.decode(
            ['bool'],
            utils.hexDataSlice(rc.events?.[0].data, 0)
        )
        console.log(`New sale state is: ${state}`);
    });