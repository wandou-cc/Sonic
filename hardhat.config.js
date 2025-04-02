require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // Sonic 主网配置
    sonic: {
      url: "https://rpc.soniclabs.com",
      chainId: 146,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
    },
    // Sonic 测试网配置 (Blaze testnet)
    "sonic-testnet": {
      url: "https://rpc.blaze.soniclabs.com", // 测试网RPC
      chainId: 57054, // 测试网链ID
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
    },
    // 本地开发网络
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
  },
  etherscan: {
    // Sonic 区块链浏览器配置 (如果需要验证合约)
    apiKey: {
      sonic: process.env.SONIC_API_KEY || "dummy", // Sonic可能不需要API key
      "sonic-testnet": process.env.SONIC_TESTNET_API_KEY || "dummy",
    },
    customChains: [
      {
        network: "sonic",
        chainId: 146,
        urls: {
          apiURL: "https://api.sonicscan.org/api", // 假设的API URL
          browserURL: "https://sonicscan.org", // 假设的浏览器URL
        },
      },
      {
        network: "sonic-testnet",
        chainId: 57054,
        urls: {
          apiURL: "https://api.testnet.sonicscan.org/api", // 假设的测试网API URL
          browserURL: "https://testnet.sonicscan.org", // 假设的测试网浏览器URL
        },
      },
    ],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  mocha: {
    timeout: 40000,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
}; 