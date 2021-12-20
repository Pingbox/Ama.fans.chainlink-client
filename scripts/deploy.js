// const hre = require("hardhat");
web3 = require('web3')
namehash = require('eth-ens-namehash')

const { expect, assert } = require('chai');
require('dotenv').config()

const DURATION = 31536000
const ZERO_BYTES = "0x0000000000000000000000000000000000000000000000000000000000000000"
const WRAPPERADDRESS = "0x0000000000000000000000000000000000000000"
const JOB_ID = web3.utils.toHex(process.env.EXTERNAL_JOBID.replace("-", ""))
const initializeData = Buffer.from('');
const chainlinkAuthorisedSenders = process.env.CHAINLINK_AUTHORIZED_SENDERS
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
    await amaClClientProxy.initialize(amaENSClientAddress,
                                      owner.address,
                                      oracle.address,
                                      JOB_ID)
    console.log("success")

    console.log("\n", "Transfffering tokens to AMAClClient proxy contract")
    await owner.transfer(transparentUpgradeableProxy.address, 100000000000000000);
    console.log("success")

    console.log("\n", "Transfffering tokens to AMAClClient proxy contract")
    // await owner.transfer(feeCollector.address, 100000000000000000);
    await owner.sendTransaction({
      to: transparentUpgradeableProxy.address,
      value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
    });
    console.log("success")

  }



  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });