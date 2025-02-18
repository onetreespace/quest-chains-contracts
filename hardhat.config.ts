import '@nomicfoundation/hardhat-toolbox';

import dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

if (!process.env.PRIVATE_KEY && !process.env.MNEMONIC) {
  console.error('invalid env variable: PRIVATE_KEY or MNEMONIC');
  process.exit(1);
}

const accounts = process.env.MNEMONIC
  ? { mnemonic: process.env.MNEMONIC }
  : [process.env.PRIVATE_KEY!];

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.26',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
        },
      },
    ],
  },
  networks: {
    optimism: {
      url: 'https://mainnet.optimism.io',
      accounts,
    },
    gnosis: {
      url: `https://rpc.gnosischain.com`,
      accounts,
    },
    polygon: {
      url: 'https://rpc-mainnet.maticvigil.com',
      accounts,
    },
    arbitrumOne: {
      url: 'https://arb1.arbitrum.io/rpc',
      accounts,
    },
    sepolia: {
      url: 'https://1rpc.io/sepolia',
      accounts,
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
      accounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === 'true',
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY!,
      polygon: process.env.POLYGONSCAN_API_KEY!,
      gnosis: process.env.GNOSISSCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      holesky: process.env.ETHERSCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'holesky',
        chainId: 17000,
        urls: {
          apiURL: 'https://api-holesky.etherscan.io/api',
          browserURL: 'https://holesky.etherscan.io',
        },
      },
    ],
  },
  typechain: {
    outDir: 'types',
  },
};

export default config;
