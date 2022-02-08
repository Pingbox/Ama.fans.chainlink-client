//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./chainlink/v0.7/ChainlinkClient.sol";
import "./AmaChainLinkClientStorage.sol";
import "./proxy/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./IAmaENSClient.sol";
import "./chainlink/v0.7/interfaces/LinkTokenInterface.sol";
import "./access/AccessControlUpgradeable.sol";

contract AmaChainLinkClient is AmaChainLinkClientStorage, 
                    Initializable, 
                    ChainlinkClient, 
                    ContextUpgradeable, 
                    AccessControlUpgradeable{
    using Chainlink for Chainlink.Request;
    event RequestFulfilled(
        address indexed _address,
        bytes  data
        );

    event RequestErrored(
        address indexed _address,
        bytes  data
        );
        
    event DomainRegistered(
        address indexed useraddress,
        bytes32 indexed nodehash,
        uint256 indexed twitterId,
        string twitterUsername,
        string label
        );

    event DifferentSubDomainAllowed(
        address indexed _address        
        );  
    
    modifier onlyRole (bytes32 _role) {
        require(hasRole(_role, _msgSender()), "MISSING_ROLE");
        _;
    }
    
    function keccakHash(string memory _string)  public pure returns (bytes32){
        return keccak256(abi.encodePacked(_string));
    }
    function initialize( 
                    address _owner,
                    address _oracle,
                    bytes32 _jobId) external initializer{
        //rinkeBy
        // setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        // setChainlinkOracle(0x7fc02a01709718b25BF6E2F48D575Fef4682250F);
        // jobId = "f6310343fb8c486b90d78ac4d14ec440";
        
        
        //Fuji Testnet        
        setChainlinkToken(0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = 1 * 10 ** 16; // (Varies by network and job)
        expiration = block.timestamp + 15 minutes;

        // ensContract = ENS(_ensAddress);
        // amaENSclientContract = IAmaENSClient(_amaENSclientAddress);
        __Context_init_unchained();
        __AccessControl_init_unchained();
        super._setupRole(DEFAULT_ADMIN_ROLE, _owner);
        super._setupRole(GOVERNANCE_ROLE, _owner);
        super._setRoleAdmin(GOVERNANCE_ROLE, DEFAULT_ADMIN_ROLE);    
        }
  
    
    function setJobId(bytes32 _jobId) 
        external 
        onlyRole(GOVERNANCE_ROLE) {
            jobId = _jobId;
        }
    
    function setOracle(address _address) 
        external 
        onlyRole(GOVERNANCE_ROLE) {
            setChainlinkOracle(_address);
        }
  
    modifier ethAddressVerified(){
        require(results[_msgSender()].verifiedOnChain == false, "ADDRESS_ALREADY_VERIFIED");
        _;
    }
    
    modifier twitterUsernameVerified(string memory _twitterUsername){
        bytes32 _hash = keccakHash(_twitterUsername);
        require(twitterUsernameToAddress[_hash] == address(0x0), "TWITTER_USERNAME_ALREADY_CLAIMED");
        _;
    }
    
    function keccakHashBytes(bytes calldata _string)  public pure returns (bytes32){
        return keccak256(_string);
    }
    
    
    function requestTwitterVerification(string calldata _twitterUsername) 
                            public
                            ethAddressVerified()
                            twitterUsernameVerified(_twitterUsername)
                            returns(bytes32){

    	Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillBytes.selector);
    	req.add("twitter_username", _twitterUsername);
        req.addBytes("address_bytes", abi.encodePacked(_msgSender()));
        req.add("path", "result");

        // req.add("copyPath", "RAW.ETH.USD.LASTMARKET");
        // bytes32  _reqID =  requestOracleData(req, fee);
        bytes32  _reqID =  requestOracleData(req, fee);

    	results[_msgSender()].reqID = _reqID;
    	results[_msgSender()].twitterUsername = _twitterUsername;

    	addressRequestIDs[_reqID] = _msgSender();

    	return _reqID;
    }
    
    //callback function
    function fulfillBytes(bytes32 _requestId, 
                    bytes calldata bytesData) 
                    public 
                    recordChainlinkFulfillment(_requestId) {
    	   //require(_msgSender() == oracle, "Only operator can fullfill the request");
    	   address _requester =  addressRequestIDs[_requestId];

    	   if (bytesData.length >100 ){
    	   
        	   results[_requester].verifiedOnChain = true;
        	   results[_requester].data = bytesData;
                _afterVerification(_requester, bytesData);
        	   delete addressRequestIDs[_requestId];
        	   emit RequestFulfilled(_requester,  bytesData);
        	   return;
    	   }
    	delete results[_requester].twitterUsername;
    	emit RequestErrored(_requester,  bytesData);
    }
    
    function cancelRequest() public {
         Response memory _response = results[_msgSender()];
        // cancellation must be called from the callback address specified in the request
        cancelChainlinkRequest(_response.reqID, fee, this.fulfillBytes.selector, expiration);
        // the LINK paid for the request is transfered back to the cancelling address
      }

    function _afterVerification(address sender, bytes calldata bytesData)
        internal{
        (string memory twitterUsername,,, uint256 twitterID,) = decodeData(bytesData);
        _setTwitterUsernameToAddress(twitterUsername, sender);
        twitterIdToAddress[twitterID] = _msgSender();

        emit DomainRegistered(sender, EMPTY_BYTES32, twitterID, twitterUsername, "");

    }

    function _setTwitterUsernameToAddress(string memory _twitterUsernameName, address _ethAddress) private {
        twitterUsernameToAddress[keccakHash(_twitterUsernameName)] = _ethAddress;
    }
    
    function userDetailsTwitter(address _address) 
        external 
        view 
        returns (string memory, 
                string memory, 
                string memory, 
                string memory, 
                uint256, 
                bool){
            Response memory _response = results[_address];
            require(_response.data.length != 0, "AmaCLClient: Request Verification");
            require(isPending(_response.reqID), "Please claimSubDomain");
            (,string memory nameOnTwitter, string memory profileImage, uint256 id, bool isTwitterVerified) = decodeData(_response.data);
            return (_response.twitterUsername, _response.label, nameOnTwitter, profileImage, id, isTwitterVerified );
    }
    

    function decodeData(bytes memory _bytes) 
            private 
            pure 
            returns(string memory, string memory, string memory, uint256, bool) {
        (string memory username, 
        string memory name, 
        string memory profileImage,
        uint256 id,
        bool twitterVerified) = abi.decode(_bytes, (string,string,string,uint256,bool));

    return (username, name, profileImage, id, twitterVerified);
    }
    
    
    function isPending(bytes32 _requestID) 
                    private
                    view 
                    notPendingRequest(_requestID) 
                    returns(bool){
        return true;
    }
    
    function getEncodedData()
                external
                view
                returns(bytes memory) {
        bytes32 _requestId = results[_msgSender()].reqID;
        _verificationStarted(_requestId);
        if (isPending(_requestId) == true) {
            return results[_msgSender()].data; 
        }
        return "";
    }
    
    
    function _verificationStarted(bytes32 _requestId) 
                private
                pure{
        require(_requestId != EMPTY_BYTES32, "VERIFICATION_HASNT_STARTED");
        return;
    }
    
    function withdrawLink(address _address) 
            public
            onlyRole(GOVERNANCE_ROLE) {
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        require(_link.transfer(_address, _link.balanceOf(address(this))), "UNABLE_TO_TRANSFER");
    }
    
    function balance() 
        public 
        view  
        onlyRole(GOVERNANCE_ROLE) 
        returns (uint256){
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        return  _link.balanceOf(address(this));
    }
    //TODO: figure out how to set the owner of this contract because proxy is not initialising the 
    // owner and sets it to address(0). You might have to use data while deploying proxy which sets 
    //the owner of this contract but then again if in case of upgrade, you will have to use the 
    // upgrade and call fuunction. The AMAStorage should have an owner varibale which must be set through 
    // a function while deploying the proxy.
    function deleteVerification(address _ethaddress) 
            external 
            onlyRole(GOVERNANCE_ROLE)  
            {
            delete results[_ethaddress];
    }

}