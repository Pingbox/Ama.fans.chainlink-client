require("@nomiclabs/hardhat-waffle");
// require("hardhat-abi-exporter");
// require("@nomiclabs/hardhat-solhint");
require("hardhat-gas-reporter");
const fs = require('fs');
const path = require('path');
require('dotenv').config()


let AVAX_FUJI_RPC_API_KEY =  process.env.AVAX_FUJI_RPC_API_KEY;

let FEECCOLLECTOR_PRIVATE_KEY = process.env.FEECCOLLECTOR_PRIVATE_KEY;
let ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY;
let OPERATOR_PRIVATE_KEY = process.env.OPERATOR_PRIVATE_KEY;



// Load environment variables from .env file. Suppress warnings using silent
// if this file is missing. dotenv will never modify any environment variables
// that have already been set.
// https://github.com/motdotla/dotenv
require('dotenv').config({silent: true});

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const argv = require('yargs/yargs')()
  .env('')
  .options({
    ci: {
      type: 'boolean',
      default: false,
    },
    gas: {
      alias: 'enableGasReport',
      type: 'boolean',
      default: false,
    },
    mode: {
      alias: 'compileMode',
      type: 'string',
      choices: [ 'production', 'development' ],
      default: 'development',
    },
    compiler: {
      alias: 'compileVersion',
      type: 'string',
      default: '0.8.3',
    },
  })
  .argv;
  

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      // Required for real DNS record tests
      initialDate: "2019-03-15T14:06:45.000+13:00",
      saveDeployments: false,
      tags: ["test", "legacy", "use_root"],
    },
    localhost: {
      url: "http://127.0.0.1:9545",
      saveDeployments: false,
      tags: ["test", "legacy", "use_root"],
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_ID}`,
      tags: ["test", "legacy", "use_root"],
      chainId: 3,
      accounts: [`0x${ADMIN_PRIVATE_KEY}`, `0x${FEECCOLLECTOR_PRIVATE_KEY}`, `0x${OPERATOR_PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      tags: ["legacy", "use_root"],
      chainId: 1,
      accounts: [`0x${ADMIN_PRIVATE_KEY}`, `0x${FEECCOLLECTOR_PRIVATE_KEY}`, `0x${OPERATOR_PRIVATE_KEY}`]
    },
    fujinet: {
      url: `${process.env.RPC_URL}`,
      accounts: [`0x${ADMIN_PRIVATE_KEY}`, `0x${FEECCOLLECTOR_PRIVATE_KEY}`, `0x${OPERATOR_PRIVATE_KEY}`]
    }
  },
  mocha: {
  },
  abiExporter: {
    path: './build/contracts',
    clear: true,
    flat: true,
    spacing: 2
  },
  solidity: {
    compilers: [
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000,
          }
        }
      },
      {
      version: "0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 10000,
        }
      }
    }
    ]
  },

};