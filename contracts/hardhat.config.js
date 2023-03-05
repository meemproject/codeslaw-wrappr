require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("xdeployer");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: true,
  },
  paths: {
    artifacts: "./build/artifacts",
    cache: "./build/cache",
    sources: "./src",
    tests: "./test",
  },
  typechain: {
    outDir: "./build/types",
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    alice: {
      default: 1,
    },
    bob: {
      default: 2,
    },
    carol: {
      default: 3,
    },
  },
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/3c83f2e1b043463dacd88df5e9d0c6ea",
      accounts: [process.env.PRIVATE_KEY]
    },
    ropsten: {
      url: 'https://rpc.ankr.com/eth_ropsten',
    },
    optimisticEthereum: {
      url: 'https://optimism-mainnet.infura.io/v3/3c83f2e1b043463dacd88df5e9d0c6ea',
      accounts: [process.env.PRIVATE_KEY]
    },
    goerli: {
      url: 'https://rpc.ankr.com/eth_goerli',
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: 'https://polygon-rpc.com',
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      ropsten: process.env.ETHERSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
      rinkeby: process.env.ETHERSCAN_API_KEY,
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.15",
        settings: {
          optimizer: {
            enabled: true,
            runs: 11111,
          },
        },
      },
    ],
  },
  xdeploy: {
    contract: "WrapprFactory",
    constructorArgsPath: "./deploy-args.js",
    salt: "CODESLAW1",
    signer: process.env.PRIVATE_KEY,
    networks: ["polygon"],
    rpcUrls: ["https://polygon-rpc.com"],
    gasLimit: "5500000",
  },
  // xdeploy: {
  //   contract: "WrapprFactory",
  //   constructorArgsPath: "./deploy-args.js",
  //   salt: "CODESLAW1",
  //   signer: process.env.PRIVATE_KEY,
  //   networks: ["goerli"],
  //   rpcUrls: ["https://rpc.ankr.com/eth_goerli"],
  //   gasLimit: "5500000",
  // },
  mocha: {
    timeout: 200000,
  },
};