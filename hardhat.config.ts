import {HardhatUserConfig} from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import 'hardhat-typechain';
import 'hardhat-abi-exporter';
import '@openzeppelin/hardhat-upgrades';
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";
import 'hardhat-gas-reporter';

const config: HardhatUserConfig = {
    zksolc: {
        version: '1.3.8',
        compilerSource: 'binary',
    },
    networks: {
        localhost: {},
        hardhat: {
            zksync: true,
        },
        zkTestnet: {
            url: "https://zksync-era-testnet.rpc.thirdweb.com", // URL of the zkSync network RPC
            ethNetwork: "goerli", // URL of the Ethereum Web3 RPC, or the identifier of the network (e.g. `mainnet` or `goerli`)
            zksync: true,
            verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification'
        },
        zkMainnet: {
            url: "https://mainnet.era.zksync.io", // URL of the zkSync network RPC
            ethNetwork: "mainnet", // URL of the Ethereum Web3 RPC, or the identifier of the network (e.g. `mainnet` or `goerli`)
            zksync: true,
            verifyURL: 'https://zksync2-mainnet-explorer.zksync.io/contract_verification'
        }
    },
    solidity: {
        version: '0.8.18',
    },
    abiExporter: {
        path: './abi',
        clear: true,
    },
};

export default config;