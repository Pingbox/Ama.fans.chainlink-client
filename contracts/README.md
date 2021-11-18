
How to Begin and Deploy:

Link contracts 
https://docs.chain.link/docs/fulfilling-requests/
https://docs.chain.link/docs/link-token-contracts/



Operator.sol deployed on RinkeBy : 0x7fc02a01709718b25BF6E2F48D575Fef4682250F
AMATwitterClient address on etherscan is: 0x70d8f4d29ea5086Ae85B61D08849D0fC1E317860




Job spec for twitter verification

```

{
 "initiators": [
   {
     "type": "runlog",
     "params": {
       "address": "0x7fc02a01709718b25BF6E2F48D575Fef4682250F"
     }
   }
 ],
 "tasks": [
   {
     "type":  "twitter-username-verification",
     "confirmations": null,
     "params": {
     }
   },
   {
     "type": "copy",
     "confirmations": null,
     "params": {
}
   },

   {
      "type": "jsonparse"
    },
    {
      "type": "resultcollect"
    },

   {
     "type": "ethtx",
     "confirmations": null,
     "params": {
        "abiEncoding": [
          "bytes32",
          "bytes"
        ]
      }
   }
 ],
 "startAt": null,
 "endAt": null
}

```
Points to not in the above jobSpec:
1. twitter-username-verification is the name of the bridge which has to be created on the node.

   
   
step6: Deploy contract AMATwitterClient.sol and transfer link tokens to the deployed address. These links token will 
be charged by the oracle contract for every invocation.

Step7: Call the function verifyUsername with relevant params and ideally you should see a new RUN for the job 
created in the step 5 on the chainlin node created in the step1.


NOTE: Do not intialize implementation contracts from the owner of ProxyAdmin. It will have side effects.
for amafans.eth
RinkeBy Addresses
Operator.sol deployed at : 0x7fc02a01709718b25BF6E2F48D575Fef4682250F
//PublicKeyResolver: 0xad07269c9Ac10fbE29A39575f3A811AD063C8f32 ||| officialPublicKeyRsolverOnMainnet: 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41
officialENS RinkeBy: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
Namehash for amafanstest1.eth : 0xad6c3a0d80abb7a479548ef46b2b03fc0f808c44760d4c6e015083d9616d6470
Namewrapper: 0x0000000000000000000000000000000000000000




NOTE: dont deploy poxyAdmin and AMAClient through deploy_amaclient.js script as somehow the contracts are not getting deployed (both AmaClient and Proxyadmin)
Deploy them from remix and then use their address to deploy TransparentUpgradeableProxy contract.


If you are doing it for the first time on a new chainID
1. Make a chainlink node and deploy a server where your chainlink adapter will be run.
2. Make a bridge with this chainlink adapter on the chainlink node and Name it something.
3. Make a job on your chainlink node with the Jobspec defined above (dont forget to chain the type name int he task and rename it the bridge name).
4. Deploy operator.sol 
5. Got to your CHainlink node from step1 under jeys section and find out the address of the node . Call methos setAuthorisedSenders with the 
address of this node address; this is just to allow your node to send response to the operator.sol example .["0xC344890Cf9844E30DeeE57Ee868E57600043434a"]
6. Deploy PublicKeyResolver with ens contract address or use the official one (since it is not behind proxy, The operator mappig will be gone if you do redeployment)
7. Deploy ProxyAdmin or use the existing one ( if you already have deployed for Reputation/Posts contracts).
8. Deploy the AmaClient.sol 
9. Make sure you do steps 7 & 8 from remix only, There is some problem with hardhat scripts ( Not actually deploying these contracts).
10. Now deploy TransparentUpgradeableProxy from scripts/deploy_amaclient.js using the address of PoxyAdmin and AmaClient. Call it AmaClientProxy.
11. Go to you ENS app and change the controller of the concerned domain to the address of AmaClientProxy.
12. Transfer chainlink to AmaClientProxy, otherwise it will be unable to submit requests to operator.sol.

Now, for once you will have to ask users to call setApprovalForAll function on PublicKeyResolver with operator=AmaClientProxy and approved=True ; so that 
AmaClientProxy can take actions on behalf of the user on PublicKeyResolver.



If you are upgrading logic on  AmaClient.sol
1. Load the ProxyAdmin contract from ProxyAdmin address mentioned above.
2. Deploy your new AmaClient.sol, call its address as UpgradeAMAClient.
3. Make sure you are logged in with the owner of ProxyAdmin and call upgrade wiht proxy=AmaClientProxy and implementation=UpgradeAMAClient.
4. Now every call on AmaClientProxy will go to the contract you deployed on step2.



#this isnt required as users cant set their primary ENS as their subdomain. No point of setting up reverse records.
For setting up reverse records: RinkeBy
1. The reverse registrar is setup at 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c
2. Load the old registrar Contract at this address.
3. Now, User has to call the function setName with the subdomain allotted to him for example graphicaldot.amafanstest1.eth.
4. Once approved, You can go to etherscan and check the reverse domain lookup.
5. Call function     function getNameFromAddress(address _address) external view returns (string memory) to get the 
reverse record for the address.




To Find NameHash: https://swolfeyes.github.io/ethereum-namehash-calculator/


Addresses (Rinkyby):
ENSRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e (No interaction is required from FrontEnd)
PublicKeyResolver: 0x3dec55268f6F154CF47C688A32DA1ef661CE1Bd3 (Must be used to get aproval from user to manage his subdomain)
ProxyAdmin: 0xADb259cC59666257e0e144D00eBaF5f8ae3E6d3A (No interaction is required from frontend)
AMAclient: 0x68957F581C0ab11f2f1e4Fbb5Cf0d5c75ac93480
AmaClientProxy: 0x92Fc84e38ce9Cb55e58Bdc53b1f37b4F50653A81 (Must be used for twitterVerification, claimSubdomain)



FujiTestnet Deployment:
Operator.sol 0xf6bB26A724655553A5046b62D41e29bB29DA1AeE
ProxyAdmin: 0x291bbf7F5712ea859C0D8851913e32a47D95FDB9
AMAClient: 0xD619E68A3b7622024929903E1Cd6Cd9EF269ceE7
TransparentUpgradeableProxy: 0x4173d1D66CC6aD2735945e7763754e003846E20F



TODO:
- [ ] NameWrapper contracts for subdomains and reverse records on ENS. ENS team hasnt confirmed yet if their Namewrapper contracts are audited and production ready.
- [ ] Handling fork chains requests failing on the chainlink.
- [ ] Setting up ReverseRegistrar.
- [ ] Setting owner of the Logic contract through UpgradeAndCall call from TranparentUpgradeableProxy.
- [ ] Multiple servers for handing chainlink requests from the operator.sol.
- [done] Reduce the fee required by Operator.sol to fulfil requests, Right now it stands at 1 Link which is too high. 
- [ ]Deployment on Avalanche and Arbitrum to check the cost fo transactions.
- [done ] Integration of AMAClient.sol with Posts.sol contracts to ease address/name resolution.
- [] Test with official PublicKeyResolver deployed by the ENS team.