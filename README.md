

#### Latest Deployments


- Operator/orcale.sol: 0x7d346F96F1912e741B0eF5F74E7179584F4479A2
- ProxyAdmin: 0x494aCE95BaB582805e556a152629f23Aa45bB0d8
- AMACLClient: 0xb8FDF8e587baF78d3C34e77c21f75B0F6c48ddab
- ProxyAddress: 0xf890d1b4ddc685369fd2ADE65A83522a0E3A185F




This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

- #### Job spec for twitter verification
- ##### Chainlink JobV1 Specification

```
{
  "name": "AA",
  "initiators": [
    {
      "id": 5,
      "jobSpecId": "162a8d42-5a5f-4a17-bdae-6d2858039abf",
      "type": "runlog",
      "params": {
        "address": "0xf6bb26a724655553a5046b62d41e29bb29da1aee"
      }
    }
  ],
  "tasks": [
    {
      "jobSpecId": "162a8d425a5f4a17bdae6d2858039abf",
      "type": "twitter-username-verification"
    },
    {
      "jobSpecId": "162a8d425a5f4a17bdae6d2858039abf",
      "type": "copy"
    },
    {
      "jobSpecId": "162a8d425a5f4a17bdae6d2858039abf",
      "type": "jsonparse"
    },
    
      "jobSpecId": "162a8d425a5f4a17bdae6d2858039abf",
      "type": "resultcollect"
    },
    {
      "jobSpecId": "162a8d425a5f4a17bdae6d2858039abf",
      "type": "ethtx",
      "params": {
        "abiEncoding": [
          "bytes32",
          "bytes"
        ]
      }
    }
  ]
}
```

- ##### Chainlink jobv2 specification

```
type = "directrequest"
schemaVersion = 1
name = "Version0.4"
contractAddress = "0x8aD2f78b9E05628C32096DB3575687A9Ee2FCF74"
externalJobID = "1b1fb378-03b3-482c-87d1-47f6f50a5706"
maxTaskDuration = "0s"
observationSource = """
  decode_log   [type="ethabidecodelog" abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4    callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)" data="$(jobRun.logData)" topics="$(jobRun.logTopics)"]
  decode_cbor  [type="cborparse" data="$(decode_log.data)"] send_to_bridge [type="bridge"  name="twitter-username-verification" requestData="{ \\"data\\": {\\"twitter_username\\": $(decode_cbor.twitter_username), \\"address_bytes\\":  $(decode_cbor.address_bytes)}}"]
  parse       [type="jsonparse" data="$(send_to_bridge)" path="result"] 
  encode_data [type="ethabiencode" abi="(bytes32 requestId, bytes memory bytesData)", data="{\\"requestId\\": $(decode_log.requestId),  \\"bytesData\\": $(parse)}"]
  encode_tx   [type="ethabiencode" abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration,bytes data)" data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\": $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr),\\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_data)}"]
  submit_tx [type="ethtx" to="0x8aD2f78b9E05628C32096DB3575687A9Ee2FCF74" data="$(encode_tx)"]
  decode_log -> decode_cbor -> send_to_bridge -> parse -> encode_data -> encode_tx -> submit_tx
"""


```
Points to not in the above jobSpec:

- ##### twitter-username-verification is the name of the bridge which has to be created on the node.
- ##### If you are doing it for the first time on a new chainID

1. Make a chainlink node and deploy a server where your chainlink adapter will be run.
2. Make a bridge with this chainlink adapter on the chainlink node and Name it something.
3. Make a job on your chainlink node with the Jobspec defined above (dont forget to chain the type name int he task and rename it the bridge name).
4. Deploy operator.sol
5. Got to your CHainlink node from step1 under keys section and find out the address of the node . Call methos setAuthorisedSenders with the address of this node address; this is just to allow your node to send response to the operator.sol example.
6. Deploy ProxyAdmin or use the existing one ( if you already have deployed for Reputation/Posts contracts).
7. Deploy the AmaCLClient.sol
8. Now deploy TransparentUpgradeableProxy from scripts/deploy_amaclient.js using the address of PoxyAdmin and AmaClient. Call it AmaClientProxy.
9. Get the jobid from the chainlinks nodes, 

```
contract A{
    bytes32 public JOB_ID;
    function jobId()
        external {
        JOB_ID = "f6310343fb8c486b90d78ac4d14ec440";
    }
```
Use this to get the jobid in bytes32 format.
10. Transfer chainlink to AmaClientProxy, otherwise it will be unable to submit requests to operator.sol.
11. Test it with a test 
9. Go to you ENS app and change the controller of the concerned domain to the address of AmaClientProxy.
10. 

Now, for once you will have to ask users to call setApprovalForAll function on PublicKeyResolver with operator=AmaClientProxy and approved=True ; so that AmaClientProxy can take actions on behalf of the user on PublicKeyResolver.

If you are upgrading logic on AmaClient.sol

1. Load the ProxyAdmin contract from ProxyAdmin address mentioned above.
2. Deploy your new AmaClient.sol, call its address as UpgradeAMAClient.
3. Make sure you are logged in with the owner of ProxyAdmin and call upgrade wiht proxy=AmaClientProxy and implementation=UpgradeAMAClient.
4. Now every call on AmaClientProxy will go to the contract you deployed on step2.
#this isnt required as users cant set their primary ENS as their subdomain. No point of setting up reverse records. For setting up reverse records: RinkeBy

Now, User has to call the function setName with the subdomain allotted to him for example graphicaldot.amafans
Once approved, You can go to etherscan and check the reverse domain lookup.
Call function function getNameFromAddress(address _address) external view returns (string memory) to get the reverse record for the address.
To Find NameHash: https://swolfeyes.github.io/ethereum-namehash-calculator/ Owner: 0xFfc3CFEDe3b7fEb052B4C1299Ba161d12AeDf135

Find jobID
