

Link contracts 
https://docs.chain.link/docs/fulfilling-requests/
https://docs.chain.link/docs/link-token-contracts/






Step 1:
Follow the documenation to host a ndoe operator on aws and host the node operator.
the node will automatically generate an ethereum address and you have to fund this address 
with ethereum as it eventually pushed the transactions on chain.

Step2: 
Deploy the smart contract Oracle.sol present in the chainlink directory. Find the appropriate link 
token address (rinkyby, kovan or mainnet) and deploy this smart contract.

Step3:
Call the function setFulfilmentPermission on the oracle.sol contract with _node as the ethereum 
address generated on the chainlink node in step1 and _allowed as true. This actually allows 
your node to pick up the jobs created by the oracle contract.

Step4:
You need to host an external adaptor on serverless or an AWS instance with https protocol.
This instance shaould accept incoming requests and return results. 
Add a bridge on your chainlink node with the URL for this aws instance or ALB. 

Step4:
GO to your node from step 1 and navigate to job section. Replace the oracle.sol address in the params 
and click on add. The first task is the bridge name we have created in the step4.
and address is the address of the deployed oracle.sol contract.



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
2. Third step used ethbool as the result is a boolean whether the twitter account has tweeted the address or not. Other types available for decoding are  
   https://docs.chain.link/docs/fulfilling-requests/
   
   
step6: Deploy contract AMATwitterClient.sol and transfer link tokens to the deployed address. These links token will 
be charged by the oracle contract for every invocation.

Step7: call the function verifyUsername with relevant params and ideally you should see a new RUN for the job 
created in the step 5 on the chainlin node created in the step1.




TODO:
Reduce the fees required to call functions in Operator.sol
