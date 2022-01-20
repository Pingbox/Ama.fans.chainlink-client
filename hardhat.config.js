/*
ganache-cli -h 0.0.0.0 --account="0x5c8f4ccb3a1936035787e74787224ff3dd94a887d8a01f22782fef7adf9c6aed,1000000000000000000000" 
                      --account="0xdda23fa3a6a01790a8fc286e5dc0c01921d0e88f2945b6047c22d9ac87ce06bc,1000000000000000000000"  
                      --account="0x5a61826c735471f845f731362678e4e9e662f4fbb19196b41640b2f36a4c8470, 1000000000000000000000" 
                      --account="0xa01cc1c891cff49daf61b7afbf4d3c35b8ff934490b4569f6c844879307854e6, 100000000000000000000" 
                      --account="0x816a3813c07aea3bcc3a1f1b7de6149dd4472e2addfb6d81912d417b400f8d1b, 1000000000000000000000" 
                      --account="0x86f305858adc09a3cdf5dec406510d2108d9acca00f84023b2e3fcbc3611d8fa, 100000000000000000000"
*/


require("@nomiclabs/hardhat-waffle");
// require('@nomiclabs/hardhat-truffle5');
require('solidity-coverage');
require("hardhat-gas-reporter");

const fs = require('fs');
const path = require('path');
require('dotenv').config()



let FEECCOLLECTOR_PRIVATE_KEY = process.env.FEECCOLLECTOR_PRIVATE_KEY;
let OWNER_PRIVATE_KEY = process.env.OWNER_PRIVATE_KEY;
let OPERATOR_PRIVATE_KEY = process.env.OPERATOR_PRIVATE_KEY;
let MNEMONIC=process.env.MNEMONIC


task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

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




if (argv.enableGasReport) {
  require('hardhat-gas-reporter');
}
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


const withOptimizations = argv.enableGasReport || argv.compileMode === 'production';

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [{
	    	"version": "0.7.0"
    },
	    {
		"version": "0.8.0"
	    }
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      blockGasLimit: 10000000,
      allowUnlimitedContractSize: !withOptimizations,
      accounts: {
          "mnemonic": MNEMONIC,
          "path": "m/44'/60'/0'/0",
          "initialIndex": 0,
          "count": 6
        }
        },
    localhost: {
	url: "http://localhost:7545",
      blockGasLimit: 10000000000,
      allowUnlimitedContractSize: !withOptimizations,
    },
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/${Key}",
      accounts: []
    },

    fujinet: {
      url: `${process.env.RPC_URL}`,
      accounts: [`0x${OWNER_PRIVATE_KEY}`, `0x${FEECCOLLECTOR_PRIVATE_KEY}`, `0x${OPERATOR_PRIVATE_KEY}`]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  gasReporter: {
    currency: 'INR',
    gasPrice: 21 
  },
};
