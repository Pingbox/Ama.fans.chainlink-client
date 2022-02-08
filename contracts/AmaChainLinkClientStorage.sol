
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;



contract AmaChainLinkClientStorage{
    // using Chainlink for Chainlink.Request;
    // bytes32 public constant ADDRESS_ALREADY_VERIFIED = "001001";
    // bytes32 public constant ADDRESS_NOT_VERIFIED = "001002";
    // bytes32 public constant TWITTER_USERNAME_ALREADY_CLAIMED = "001003";
    // bytes32 public constant VERIFICATION_HASNT_STARTED = "001004";
    // bytes32 public constant UNABLE_TO_TRANSFER = "001005";
    bytes32 public constant EMPTY_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant GOVERNANCE_ROLE =  keccak256("GOVERNANCE");

    struct Response {
        bytes32 reqID;
        string username;
        string label;
        bool verifiedOnChain; //if the address has actually posted the tweet on twitter account and has been verified
        bytes data; //[proposedSubDomain,nameOnTwitter,ethAddress,isTwitterVerified,isOnChainVerified]
    }

    // IAmaENSClient public amaENSclientContract;
    address public oracle;
    bytes32 public jobId;
    uint256 public fee;
    uint256 public expiration;
    mapping(address => Response) public results; //eth address hash mapped to responses
    mapping(bytes32 => address ) public addressRequestIDs;
    
    // //Till the time Namewrapper isnt integrated, this mapping will be ued to 
    // // addresses associated with the keccakhash of the onchainUsername, 
    // //The onchian username could be different from the TwitterUsername because onChainUsername 
    // //is just twitterUsername without special characters.
    // mapping(bytes32 => address) public nodeHashToAddress; 

    //This maps the Keccakhash of the twitter username to the address of the user. 
    //This provides a quick way to decide if the TwitterUsername is already associated with an 
    //Ethereum address and if yes, Then by whom.
    mapping(bytes32 => address) public usernameToAddress;
    mapping(uint256 => address) internal socialIdToAddress;
}