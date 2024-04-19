// import * as dotenvenc from '@chainlink/env-enc'
// dotenvenc.config();

import * as dotenv from 'dotenv';
dotenv.config();

import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
// import './tasks';
// import 'hardhat-change-network';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ethers';

// Import MNEMONIC or single private key
const MNEMONIC = process.env.MNEMONIC || "test test test test test test test test test test test junk";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const INFURA = process.env.INFURA || "";
const ETHEREUM_API_KEY = process.env.ETHEREUM_API_KEY || "api-key";
const OPTIMISM_API_KEY = process.env.OPTIMISM_API_KEY || "api-key";
const BSC_API_KEY = process.env.BSC_API_KEY || "api-key";
const FANTOM_API_KEY = process.env.FANTOM_API_KEY || "api-key";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "api-key";
const ARBITRUM_API_KEY = process.env.ARBITRUM_API_KEY || "api-key";

const config: HardhatUserConfig = {
  solidity: '0.8.19',
  networks: {
    hardhat: {
      gas: 30e6,
      blockGasLimit: 30e6,
      allowUnlimitedContractSize: true,
    },
    localhost: {
      gas: 30e6,
      blockGasLimit: 30e6,
      url: 'http://localhost:8545',
      loggingEnabled: true,
    },
    mainnet: {
      gasPrice: 'auto',
      url: 'https://mainnet.infura.io/v3/' + INFURA,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    sepolia: {
      url: 'https://sepolia.infura.io/v3/' + process.env.INFURA,
      chainId: 11155111,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    optimisticEthereum: {
      // url: 'https://optimism-mainnet.infura.io/v3/' + INFURA,
      url: 'https://mainnet.optimism.io',
      chainId: 10,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    optimismSepolia: {
      url: 'https://optimism-sepolia.blockpi.network/v1/rpc/public',
      chainId: 11155420,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    polygon: {
      url: 'https://polygon-mainnet.infura.io/v3/' + INFURA,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    polygonMumbai: {
      url: 'https://polygon-mumbai.infura.io/v3/' + INFURA,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
      gasPrice: 80000000000,
    },
    bsc: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      //gasPrice: 5000000000,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    bscTestnet: {
      url: `https://data-seed-prebsc-1-s1.bnbchain.org:8545`,
      chainId: 97,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    arbitrumOne: {
      // url: 'https://arbitrum-mainnet.infura.io/v3/' + INFURA,
      url: 'https://arb1.arbitrum.io/rpc',
      chainId: 42161,
      //gasPrice: 5000000000,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    arbitrumSepolia: {
      // gasPrice: 10000,
      url: 'https://sepolia-rollup.arbitrum.io/rpc',
      chainId: 421614,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
    ftmTestnet: {
      // url: `https://endpoints.omniatech.io/v1/fantom/testnet/public`,
      // url: `https://rpc.ankr.com/fantom_testnet`,
      url: `https://fantom-testnet.public.blastapi.io`,
      chainId: 4002,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : { mnemonic: MNEMONIC },
    },
  },
  typechain: {
    externalArtifacts: ['./abi/*.json']
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts'
  },
  etherscan: {
    // not supported by default by hardhat
    customChains: [
      {
        network: 'optimismSepolia',
        chainId: 11155420,
        urls: {
          apiURL: 'https://api-sepolia-optimistic.etherscan.io/api',
          browserURL: 'https://sepolia-optimism.etherscan.io/',
        },
      },
      {
        network: 'arbitrumSepolia',
        chainId: 421614,
        urls: {
          apiURL: 'https://api-sepolia.arbiscan.io/api',
          browserURL: 'https://sepolia.arbiscan.io/',
        },
      },
    ],
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      // Ethereum
      mainnet: ETHEREUM_API_KEY,
      sepolia: ETHEREUM_API_KEY,
      // Optimism
      optimisticEthereum: OPTIMISM_API_KEY,
      optimismSepolia: OPTIMISM_API_KEY,
      // polygon
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      // Arbitrum
      arbitrumOne: ARBITRUM_API_KEY,
      arbitrumSepolia: ARBITRUM_API_KEY,
      // Bsc
      bsc: BSC_API_KEY,
      bscTestnet: BSC_API_KEY,
      // Fantom
      ftmTestnet: FANTOM_API_KEY,
      //
    },
  },
  mocha: {
    timeout: 40000000000000
},
};

export default config;
