// const hre = require("hardhat");
web3 = require('web3')
namehash = require('eth-ens-namehash')

const { expect, assert } = require('chai');
const { link } = require('ethereum-waffle');
require('dotenv').config()

const DURATION = 31536000
const ZERO_BYTES = "0x0000000000000000000000000000000000000000000000000000000000000000"
const WRAPPERADDRESS = "0x0000000000000000000000000000000000000000"
const JOB_ID = web3.utils.toHex(process.env.EXTERNAL_JOBID.split("-").join(""))
const initializeData = Buffer.from('');
const chainlinkAuthorisedSenders = process.env.CHAINLINK_AUTHORIZED_SENDERS.split(", ")
const chainlinkTokenAddress = process.env.CHAINLINK_TOKEN_ADDRESS
const amaENSClientAddress = process.env.AMAENSCLIENT_ADDRESS

async function main() {

  // We get the contract to deploy
    // const Greeter = await ethers.getContractFactory("Greeter");
    // hre.ethers.provider.connection.url = "https://rinkeby.infura.io/v3/c3ba436414314c69904f0ee1d5132a87";
    const [owner,  feeCollector, operator] = await ethers.getSigners();

    const operatorContractF = await ethers.getContractFactory("Operator");
    const amaCLClientContractF = await ethers.getContractFactory("AmaCLClient");
    const proxyAdminContractF = await ethers.getContractFactory("ProxyAdmin");
    // const erc20ContractF = await ethers.getContractFactory("IERC20");
    // const linkToken = await erc20ContractF.attach(chainlinkTokenAddress);
    const linkToken = await hre.ethers.getContractAt("IERC20", chainlinkTokenAddress);


    const transparentUpgradeableProxyContractF = await ethers.getContractFactory("TransparentUpgradeableProxy");

    let oracle;
    let amaClClient ;
    let proxyAdmin;
    let transparentUpgradeableProxy;
    let amaClClientProxy ;

    console.log(`Owner address ${owner.address}`)
    console.log(`Feecollector address ${feeCollector.address}`)
    console.log(`operator address ${operator.address}`)
    console.log(`chainlink job authorised senders ${chainlinkAuthorisedSenders}`)

    console.log(`Chainlink JobID generated on chainlink client nodes is ${JOB_ID}`)
    console.log(`AMAEnsClient Address  ${amaENSClientAddress}`)
    console.log(`Chainlink token Address  ${chainlinkTokenAddress}`)

    // console.log("owner balance:", (await owner.getBalance()).toString());
    // console.log("operator balance:", (await operator.getBalance()).toString());
    // console.log("feeCollector balance:", (await feeCollector.getBalance()).toString());
    amaClClientProxy = await amaCLClientContractF.attach("0xd0BEccb93df005eD13902D8b4FF91BAF0c798DFb");



    console.log("\n", "Deploying Operator")
    oracle = await operatorContractF.deploy(chainlinkTokenAddress, owner.address);
    await oracle.deployed();
    console.log( "Operator contract", oracle.address);


    // oracle = await operatorContractF.attach("0x2e81a14bE9521F2084a498Bd614d64b0D4A6f662");
    console.log("\n", "Setting chainlink authroized senders on operator contract")
    await oracle.connect(owner).setAuthorizedSenders(chainlinkAuthorisedSenders)





    console.log("\n", "Deploying ProxyAdmin")
    proxyAdmin = await proxyAdminContractF.deploy();
    await proxyAdmin.deployed();
    console.log( "proxyAdmin contract", proxyAdmin.address);


    console.log("\n", "Deploying AMACLClient")
    amaClClient = await amaCLClientContractF.deploy();
    await amaClClient.deployed();
    console.log( "AMAClClient contract address", amaClClient.address);


    console.log("\n", "Deploying TransparentUpgradeableProxy")
    transparentUpgradeableProxy = await transparentUpgradeableProxyContractF.deploy(amaClClient.address, proxyAdmin.address, initializeData);
    await transparentUpgradeableProxy.deployed();
    console.log( "TransparentUpgradeableProxy contract address", transparentUpgradeableProxy.address);


    console.log("\n", "Intitializing amaClClient contract")
    amaClClientProxy = await amaCLClientContractF.attach(transparentUpgradeableProxy.address);
    await amaClClientProxy.connect(operator).initialize(amaENSClientAddress,
                                      owner.address,
                                      oracle.address,
                                      JOB_ID)
    console.log("success")

    console.log("\n", "Transferring tokens to AMAClClient proxy contract")
    await linkToken.connect(owner).transfer(amaClClientProxy.address,  ethers.utils.parseEther("1.0"));
    console.log("success")


  }

/***
 *  Deploying Operator
Operator contract 0x22547A8361DbAEC60A3B2F66aca44C69Ad1824F9

 Setting chainlink authroized senders on operator contract

 Deploying ProxyAdmin
proxyAdmin contract 0xD96265450f6f526C78dE0f0850BeC3bbEC942976

 Deploying AMACLClient
AMAClClient contract address 0xCB5908413BE3db67b18502dBBCCa31B27DCfc1f3

 Deploying TransparentUpgradeableProxy
TransparentUpgradeableProxy contract address 0xd0BEccb93df005eD13902D8b4FF91BAF0c798DFb
 * 
 * 
 */

  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });