import {Contract, Provider, Wallet} from "zksync-web3";
import * as abi from './abi.json'
import layers from '../assets/layers.json';
import {readFileSync} from "fs";

Object.defineProperty(Array.prototype, 'chunk_inefficient', {
  value: function(chunkSize) {
    var array = this;
    return [].concat.apply([],
      array.map(function(elem, i) {
        return i % chunkSize ? [] : [array.slice(i, i + chunkSize)];
      })
    );
  }
});

async function main(): Promise<void> {
    const provider = new Provider('https://mainnet.era.zksync.io');
    const wallet = new Wallet("...", provider);

    const contract = new Contract(
        '0xd96D88064e56144146A41b17D065400FdD864B85',
        abi.abi,
        wallet,
    );

    const mapOfNames = {
        0: 'Background',
        1: 'Body',
        2: 'OnBody',
        3: 'OnHead',
        4: 'Beak',
        5: 'Eyes',
    }

    const colors = readFileSync(__dirname + '/../assets/colors.txt', 'utf-8');
    await contract.setColors(colors)
    console.log(`[OK] Set colors`)

    for (const el of layers) {
        await contract.clearLayer(el['id'])
        console.log(`[OK] Clear layer ${mapOfNames[el['id']]}`)
        const id = el['id']
        const data = el['data']
        if (id > 1) {
            if (data.length > 10) {
                const arrOfArr = data.chunk_inefficient(10)
                for (const l of arrOfArr) {
                    await contract.addLayerType(id, l);
                    console.log(`[OK] Uploaded layers for type: ${mapOfNames[el['id']]} part`)
                }
            } else {
                await contract.addLayerType(id, data);
                console.log(`[OK] Uploaded layers for type: ${mapOfNames[el['id']]}`)
            }
        }
    }
}

main()
    .then(() => {
        console.log('Success')
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })