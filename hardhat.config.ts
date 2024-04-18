import { HardhatUserConfig, task, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
require("@nomicfoundation/hardhat-chai-matchers")

import dotenv from 'dotenv'

dotenv.config()

console.log(process.env)


const accounts = [
  process.env.OWNER_PRIVATE_KEY as string
];

task("accounts", "Prints the list of accounts", async (_, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task(
  "balances",
  "Prints the list of accounts and their balances",
  async (_, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
      console.log(
        account.address +
          " " +
          (await hre.ethers.provider.getBalance(account.address)),
      );
    }
  },
);

console.log('BASE_API_KEY', process.env.BASE_API_KEY)

const config: HardhatUserConfig = {
  solidity: {
    // Only use Solidity default versions `>=0.8.20` for EVM networks that support the opcode `PUSH0`
    // Otherwise, use the versions `<=0.8.19`
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999_999,
      },
      evmVersion: "paris", // Prevent using the `PUSH0` opcode
    },
  },
  networks: {
    base: {
      url: `https://mainnet.base.org`,
      chainId: 8453,
      accounts
    },
    baseSepolia: {
      url: `https://sepolia.base.org`,
      chainId: 84532,
      accounts
    },
    sepolia: {
      chainId: 11155111,
      url: vars.get("ETH_SEPOLIA_TESTNET_URL", "https://rpc.sepolia.org"),
      accounts
    },
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,

    },
  },
  gasReporter: {
    enabled: true, //process.env.REPORT_GAS,
    noColors: false,
    showTimeSpent: true,
    showMethodSig: true,
    onlyCalledMethods: true,
    currency: 'USD',
    // coinmarketcap: '<key>',
  },
  etherscan: {
    // Add your own API key by getting an account at etherscan (https://etherscan.io), snowtrace (https://snowtrace.io) etc.
    // This is used for verification purposes when you want to `npx hardhat verify` your contract using Hardhat
    // The same API key works usually for both testnet and mainnet
    apiKey: {
      // For Ethereum testnets & mainnet
      mainnet: process.env.ETHERSCAN_API_KEY!,
      goerli: process.env.ETHERSCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      // For Base testnets & mainnet
      base: process.env.BASE_API_KEY!,
      baseTestnet: process.env.BASE_API_KEY!,
      baseSepolia: process.env.BASE_API_KEY!
    },
    customChains: [
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
        },
      }
    ]
  }



};

export default config;
