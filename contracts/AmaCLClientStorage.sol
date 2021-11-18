
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// import "./chainlink/v0.7/ChainlinkClient.sol";
import "./ENSInterface.sol";
import "./IAmaENSClient.sol";

abstract contract NameResolver {
    mapping (bytes32 => string) public name;
    function setName(bytes32 _node, string memory _name) public virtual;
}



abstract contract ReverseRegistrar {
    NameResolver public defaultResolver;
    function setName(bytes32 _node, string memory name) virtual public;
    function node(address addr) public virtual pure returns (bytes32);

} 

contract AmaCLClientStorage{
    // using Chainlink for Chainlink.Request;
    bytes32 constant public EMPTY_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;



    //.amafans
    //bytes32  constant public ROOT_DOMAIN_NAME_HASH = 0x038eaf1bbed157c71ba2bb3681be8be9303cab863e7482dfb7fc868b43d2d8ee;

    struct Response {
        bytes32 reqID;
        string twitterUsername;
        string label;
        bool verifiedOnChain; //if the address has actually posted the tweet on twitter account and has been verified
        bytes data; //[proposedSubDomain,nameOnTwitter,ethAddress,isTwitterVerified,isOnChainVerified]
    }
    mapping(address => Response) public results; //eth address hash mapped to responses
    mapping(bytes32 => address ) public addressRequestIDs;

    //Till the time Namewrapper isnt integrated, this mapping will be ued to 
    // addresses associated with the keccakhash of the onchainUsername, 
    //The onchian username could be different from the TwitterUsername because onChainUsername 
    //is just twitterUsername without special characters.
    mapping(bytes32 => address) public nodeHashToAddress; 

    //This maps the Keccakhash of the twitter username to the address of the user. 
    //This provides a quick way to decide if the TwitterUsername is already associated with an 
    //Ethereum address and if yes, Then by whom.
    mapping(bytes32 => address) public twitterUsernameToAddress; 
    IAmaENSClient public amaENSclientContract;
    address public oracle;
    bytes32 public jobId;
    uint256 public fee;
    address public owner;
    uint256 public expiration;

}