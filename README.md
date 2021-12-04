##  How to Begin and Deploy:

### Link contracts 
- [External Adapter request]
- [Chainlink Contracts ]

##### Job spec for twitter verification

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
    {
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

- ###### chainlink JobV2 specification
```
type                             = "directrequest"
schemaVersion          = 1
name                           = "ConversionToV2"
contractAddress        = "0xf6bB26A724655553A5046b62D41e29bB29DA1AeE"
externalJobID            = "855ad288-8a9d-4ab1-a575-dabd631bf084"
observationSource   = """

          decode_log   [type="ethabidecodelog"
                 abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address 
                  callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]
           decode_cbor  [type="cborparse" data="$(decode_log.data)"]
           send_to_bridge [type="bridge" 
                    name="twitter-username-verification" 
                    requestData="{ \\"data\\": { \\"twitter_username\\": $(decode_cbor.twitter_username),  
                     \\"address_bytes\\":  $(decode_cbor.address_bytes)}}"]
          parse       [type="jsonparse" data="$(send_to_bridge)" path="result"]
          encode_data [type="ethabiencode"
                abi="fulfillBytes(bytes32 requestID, bytes data)",
                data="{\\"requestID\\": $(decode_log.requestId),  \\"bytesData\\": $(parse)}"
                ]
         encode_tx   [type="ethabiencode"
                 abi="fulfillOracleRequest(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes32 data)"
                 data="{\\"requestId\\": $(decode_log.requestId), 
                        \\"payment\\": $(decode_log.payment), 
                        \\"callbackAddress\\": $(decode_log.callbackAddr), 
                        \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), 
                        \\"expiration\\": $(decode_log.cancelExpiration), 
                        \\"data\\": $(encode_data)}"
                 ]
        submit_tx [type="ethtx" to="0xf6bb26a724655553a5046b62d41e29bb29da1aee" data="$(encode_tx)"]
        decode_log -> decode_cbor -> send_to_bridge -> parse -> encode_data -> encode_tx -> submit_tx
"""
```

Points to not in the above jobSpec:
1. twitter-username-verification is the name of the bridge which has to be created on the node.

   
   

 #### If you are doing it for the first time on a new chainID
1. Make a chainlink node and deploy a server where your chainlink adapter will be run.
2. Make a bridge with this chainlink adapter on the chainlink node and Name it something.
3. Make a job on your chainlink node with the Jobspec defined above (dont forget to chain the type name int he task and rename it the bridge name).
4. Deploy operator.sol 
5. Got to your CHainlink node from step1 under keys section and find out the address of the node . Call methos setAuthorisedSenders with the 
address of this node address; this is just to allow your node to send response to the operator.sol example.
6. Deploy PublicKeyResolver with ens contract address or use the official one (since it is not behind proxy, The operator mappig will be gone if you do redeployment)
7. Deploy ProxyAdmin or use the existing one ( if you already have deployed for Reputation/Posts contracts).
8. Deploy the AmaCLClient.sol 
9. Make sure you do steps 7 & 8 from remix only, There is some problem with hardhat scripts ( Not actually deploying these contracts).
10. Now deploy TransparentUpgradeableProxy from scripts/deploy_amaclient.js using the address of PoxyAdmin and AmaClient. Call it AmaClientProxy.
11. Go to you ENS app and change the controller of the concerned domain to the address of AmaClientProxy.
12. Transfer chainlink to AmaClientProxy, otherwise it will be unable to submit requests to operator.sol.

Now, for once you will have to ask users to call setApprovalForAll function on PublicKeyResolver with operator=AmaClientProxy and approved=True ; so that 
AmaClientProxy can take actions on behalf of the user on PublicKeyResolver.



If you are upgrading logic on AmaClient.sol
1. Load the ProxyAdmin contract from ProxyAdmin address mentioned above.
2. Deploy your new AmaClient.sol, call its address as UpgradeAMAClient.
3. Make sure you are logged in with the owner of ProxyAdmin and call upgrade wiht proxy=AmaClientProxy and implementation=UpgradeAMAClient.
4. Now every call on AmaClientProxy will go to the contract you deployed on step2.



#this isnt required as users cant set their primary ENS as their subdomain. No point of setting up reverse records.
For setting up reverse records: RinkeBy
1. The reverse registrar is setup at 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c
2. Load the old registrar Contract at this address.
3. Now, User has to call the function setName with the subdomain allotted to him for example graphicaldot.amafans
4. Once approved, You can go to etherscan and check the reverse domain lookup.
5. Call function     function getNameFromAddress(address _address) external view returns (string memory) to get the 
reverse record for the address.




To Find NameHash: https://swolfeyes.github.io/ethereum-namehash-calculator/
Owner: 0xFfc3CFEDe3b7fEb052B4C1299Ba161d12AeDf135
##### New contracts (Fuji TestNet Deployments):
- ###### _Operator.sol_ :  0xe5E07b5240e628BA84A9B650c2372912056785F2
- ###### _LinkTokenAddress_ : 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
- ###### _AMACLClient_: 0x26E8369F26B7c40ADB36BF84d2c497C7D1839Fa2 //Dont use this contract directly, Use        TransparentUpgradeableProxy insted as a proxy for this contract.
- ###### _ProxyAdmin_: 0x7Ef3d91F0A79697DfD8Daa26D302003fcE0D5e64
- ###### _AMAClientProxy_ : 0xf7b954Bbbe16A39E251cFFeE8a4461cF0ac5Af6f


##### FujiTestnet Deployment:
- ###### _Operator.sol_ :  0xf6bB26A724655553A5046b62D41e29bB29DA1AeE
- ###### _ProxyAdmin_: 0x291bbf7F5712ea859C0D8851913e32a47D95FDB9
- ###### _AMAClClient_: 0xD619E68A3b7622024929903E1Cd6Cd9EF269ceE7 //Dont use this contract directly, Use        TransparentUpgradeableProxy insted as a proxy for this contract.
- ###### _ENSRegistry_: 0x970e7636f5e3A09a41057D6bC9E54a20CAfbf4a3
- ###### _PublicKeyResolver_: 0xe30C409CF769912f9359625c6B33bc9959d0E95f
- ###### _TransparentUpgradeableProxy_: 0x4173d1D66CC6aD2735945e7763754e003846E20F //interact with this contract with ABI of AMAClClient contract.




## Functions of Interest:
- Post a tweet with your address and #amafans tag on your twitter. 
- Call function ```requestVerification``` with the same address that you posted in twitter.
- Keep calling getEncodedData function, It will give you bytes if the request has been completed otheriwese it will raise rthis error  ```execution reverted: Request is already pending```
- To cross cheeck, you can call function ```userDetailsTwitter`` function and you will get the details of the useer which  have been fetched from twitter.
-  It is time to call ```claimSubDomain``` function with the same address. In the backend, It register the records on the ENS contract deployed on the Avax chain and alos creates a domain with the twitter details.```For example, My twitter username is graphicaldot which doesnt have any special chars so on the ENS contracts, following records will be created. graphicaldot.amafans will be associated with my address .```
> Please note: These records will exist on the ENS registry not on AMAEnsClient (which is just being used to interact with ENS registry). Also, the corresponding text records are present in the PublicResolver contract. The three keys which will be created for each subdomains 
are : 
>"name" = Name of the user on twitter
"com.twitter" = username of the user on twitter.
"twitterID" = twitterID of the user 
"avatar" = Profile image of the user on twitter
"isTwitterverified" =  If the user is verified by twitter or not.

- On ENS registry and public resolver, The records are not represented by "graphicaldot.amafans" but by the nodeHash. You can get the NameHash aka nodehash , ex Nodehash of graphicaldot.amafans is 0x5e118688372471fd6a83414a4118bbe5b310119eb1eb60e2fc159f3f65e0597f.
```
keccak256(abi.encodePacked(BASENODE, label)), where BASENODE is the namehash of amafans.
```

- One you call claimsubDomain, you can call ```owner``` function on ENSRegistry contrct with the NameHash of the domain and  it will give you the address of the owner. You can also call ```getLabel``` function on the AMACLClient contract with the address and you will get the domain name 

- "0x"+ binascii.hexlify(JOBID.encode("utf-8")).decode() , use this method if you want to update the JOBID on the contract.

### TODO:
- [] NameWrapper contracts for subdomains and reverse records on ENS. ENS team hasnt confirmed yet if their Namewrapper contracts are audited and production ready.
- [] Handling fork chains requests failing on the chainlink.
- [] Setting up ReverseRegistrar.
- [Done] GOVERNANCE and DEFAULT_ADMIN_ROLE with accesss control implementeed.
- [Done] Multiple servers for handing chainlink requests from the operator.sol.
- [Done] Reduce the fee required by Operator.sol to fulfil requests, Right now it stands at 1 Link which is too high. 
- [Done]Deployment on Avalanche and Arbitrum to check the cost fo transactions.
- [Done] Integration of AMAClient.sol with Posts.sol contracts to ease address/name resolution.


[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [External Adapter request]: <https://docs.chain.link/docs/fulfilling-requests/>
   [Chainlink Contracts ]: <https://docs.chain.link/docs/link-token-contracts/>


To set the newJob id on AMACLClint.sol 

