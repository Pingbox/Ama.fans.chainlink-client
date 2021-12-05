//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./chainlink/v0.7/ChainlinkClient.sol";
import "./AmaCLClientStorage.sol";
import "./utils/Initializable.sol";
import "./IAmaENSClient.sol";
import "./chainlink/v0.7/interfaces/LinkTokenInterface.sol";
import "./access/AccessControl.sol";

contract AmaCLClient is Initializable, ChainlinkClient, AccessControl, AmaCLClientStorage {
    using Chainlink for Chainlink.Request;
    event RequestFulfilled(
        address indexed _address,
        bytes  data
        );

    event RequestErrored(
        address indexed _address,
        bytes  data
        );
        
    event DifferentSubDomainAllowed(
        address indexed _address        
        );  
    
    modifier onlyRole (bytes32 _role) {
        require(hasRole(_role, msg.sender), "Role Missing");
        _;
    }
    
    function initialize(address _amaENSclientAddress, 
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
        amaENSclientContract = IAmaENSClient(_amaENSclientAddress);
        super._setupRole(DEFAULT_ADMIN_ROLE, _owner);
        super._setupRole(GOVERNANCE_ROLE, _owner);
        super._setRoleAdmin(GOVERNANCE_ROLE, DEFAULT_ADMIN_ROLE);    
        }
  


    function setAMAEnsClient(address _address) 
                external  
                onlyRole(GOVERNANCE_ROLE){
        amaENSclientContract = IAmaENSClient(_address);
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
        require(!results[msg.sender].verifiedOnChain, "Eth address has already been verified");
        _;
    }
    
    modifier twitterUsernameVerified(string memory _twitterUsername){
        bytes32 _hash = keccakHash(_twitterUsername);
        require(twitterUsernameToAddress[_hash] == address(0x0), "Twitter Username is already claimed");
        _;
    }
    

    
    function keccakHash(string memory _string)  public pure returns (bytes32){
        return keccak256(abi.encodePacked(_string));
    }
    
    // function keccakHashAddress()  public view returns (bytes32){
    //     return keccak256(abi.encodePacked(msg.sender));
    // }

    // function keccakHashBytes(bytes calldata _string)  public pure returns (bytes32){
    //     return keccak256(_string);
    // }
    
    
    function requestVerification(string calldata _twitterUsername) 
                            public
                            ethAddressVerified()
                            twitterUsernameVerified(_twitterUsername)
                            returns(bytes32){
        require(twitterUsernameToAddress[keccakHash(_twitterUsername)] == address(0x0), "TwitterUsername already associated with different address");

    	Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillBytes.selector);
    	req.add("twitter_username", _twitterUsername);
        req.addBytes("address_bytes", abi.encodePacked(msg.sender));
        req.add("path", "result");

        // req.add("copyPath", "RAW.ETH.USD.LASTMARKET");
        // bytes32  _reqID =  requestOracleData(req, fee);
        bytes32  _reqID =  requestOracleData(req, fee);

    	results[msg.sender].reqID = _reqID;
    	results[msg.sender].twitterUsername = _twitterUsername;

    	addressRequestIDs[_reqID] = msg.sender;

    	return _reqID;
    }
    
    //callback function
    function fulfillBytes(bytes32 _requestId, 
                    bytes calldata bytesData) 
                    public 
                    recordChainlinkFulfillment(_requestId) {
    	   //require(msg.sender == oracle, "Only operator can fullfill the request");
    	   address _requester =  addressRequestIDs[_requestId];

    	   if (bytesData.length >10 ){
    	   
        	   results[_requester].verifiedOnChain = true;
        	   results[_requester].data = bytesData;
    
        	   delete addressRequestIDs[_requestId];
        	   emit RequestFulfilled(_requester,  bytesData);
        	   return;
    	   }

        // (string memory proposedUsername,,,,) = abi.decode(bytesData, (string,string,address,bool,bool));
        // results[_ethaddressHash].onchainUsername = proposedUsername;

    	emit RequestErrored(_requester,  bytesData);
    }
    
    function cancelRequest() public {
         Response memory _response = results[msg.sender];
        // cancellation must be called from the callback address specified in the request
        cancelChainlinkRequest(_response.reqID, fee, this.fulfillBytes.selector, expiration);
        // the LINK paid for the request is transfered back to the cancelling address
      }
    
    /* proposedUsername is the twittername with no speacial chars as they arent accepted on ens subdomains.
    * if the labelahsh for this proposedUsername already exists then the user will have to call the same function 
    * with a self chosen porposedName. If clashes happens, results[_ethaddressHash].diffDomainAllowed = true 
    */
    function claimSubDomain() 
            external 
            {
        Response memory _response = results[msg.sender];
        require(_response.verifiedOnChain, "Address is not yet verified onChain");
        // (string memory label,string memory nameOnTwitter, string memory profileImage, string memory twitterID, bool isTwitterVerified, ) = 
        // decode_data(_response.data);
        
        // bytes32 nameHash = _computeNamehash(label);
        
        /* it might be a possibility that a twitterUsername has a different proposedUsername because of presence of 
        *special chars in twitterUserName, Two users can have same proposedUsername in theory. So its checking if the 
        * recordExists for the NameHash of the proposeUsername and then users will have to claim with differentProposeUsername
        
        */
        (bytes32 nodehash, string memory label) = _registerNode(msg.sender, _response.data, _response.twitterUsername);
        // _recordExists(nameHash, msg.sender);
        // ensContract.setSubnodeRecord(ROOT_DOMAIN_NAME_HASH, keccakHash(label), msg.sender,subDomainResolver, 500000);

        _setLabel(msg.sender, label);
        _setNodeHashToAddress(nodehash, msg.sender);
        _setTwitterUsernameToAddress(_response.twitterUsername, msg.sender);

    }
    
    function claimCustomSubDomain( 
                    string calldata _differentLabel)
                    external  {

        // bytes32 _ethaddressHash = keccakHash(_ethaddress);
        Response memory _response = results[msg.sender];
        require(_response.verifiedOnChain, "Address is not yet verified onChain");



        (,string memory nameOnTwitter, string memory profileImage, string memory twitterID, bool isTwitterVerified) = 
        decode_data(_response.data);

        bytes memory _new = abi.encodePacked(_differentLabel,nameOnTwitter,profileImage,twitterID,isTwitterVerified);
        (bytes32 nodehash, ) = _registerNode(msg.sender, _new, _response.twitterUsername);


        _setLabel(msg.sender, _differentLabel);

        _setNodeHashToAddress(nodehash, msg.sender);
        _setTwitterUsernameToAddress(_response.twitterUsername, msg.sender);

    }

    function _registerNode(address _owner, bytes memory _clData, string memory twitterUsername) private returns (bytes32, string memory){
        try amaENSclientContract.registerNode(_owner, _clData, twitterUsername) returns (bytes32 nodehash, string memory label) {
            return (nodehash, label);
        } catch Error(string memory _err) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            revert(_err);
        }
        
    }

    /* This function should be called only when a user has been verified with twitter but her proposedUsername
    * clashes with someother node becaue of stripping of speacial chars, In this case, The user can choose username of 
    * of her choice.
    */

    /*setting up kceccakahsh of the _differentProposedUsername/proposedUsername to the address of the users address*/
    function _setNodeHashToAddress(bytes32 _nodeHash, address _address) private {
        nodeHashToAddress[_nodeHash] = _address;
    }
    
    function _setLabel(address _requester, string memory _label) private {
        results[_requester].label = _label;
        
    }

    function _setTwitterUsernameToAddress(string memory _twitterUsernameName, address _ethAddress) private {
        twitterUsernameToAddress[keccakHash(_twitterUsernameName)] = _ethAddress;

    }



    // /* check if the node has the tewitterName already set then*/
    // function twitterNameExistsOnENS(bytes32 nameHash) internal view  {
    //     require(EMPTY_STRING_KECCAKHASH == (keccakHash(PublicResolver(subDomainResolver).text(nameHash, TWITTER_KEY))), 
    //     "TwitterName already present");
    // }
    
    function userDetailsTwitter(address _address) 
        external 
        view 
        returns (string memory, string memory, string memory, string memory, bool){
            Response memory _response = results[_address];
            require(isPending(_response.reqID), "Please claimSubDomain");
            // (string memory proposedUsername, string memory nameOnTwitter, address ethAddress,bool isTwitterVerified , ) = abi.decode(_response.data, (string,string,address,bool,bool));
            // (,string memory nameOnTwitter, string memory twitterURL, bool isTwitterVerified, ) = abi.decode(_response.data, (string,string,string,bool,bool));
            (,string memory nameOnTwitter, string memory profileImage, , bool isTwitterVerified) = decode_data(_response.data);
            return (_response.twitterUsername, _response.label, nameOnTwitter, profileImage,isTwitterVerified );
    }
    

    
    
    function getEthAddress(string memory _label) external view returns (address){
        (,bytes32 nodehash,) = amaENSclientContract.getNodeHash(_label);
        return nodeHashToAddress[nodehash];
        
    }

    function decode_data(bytes memory _bytes) private pure returns (string memory, string memory, string memory, string memory, bool) {
        (string memory username, 
        string memory name, 
        string memory profile_image,
        string memory id,
        bool twitter_verified) = abi.decode(_bytes, (string,string,string,string,bool));

    return (username, name, profile_image, id, twitter_verified);
    }
    
    
    function isPending(bytes32 _requestID) 
                    view 
                    private 
                    notPendingRequest(_requestID) 
                    returns(bool){
        return true;
    }
    
    /* this si to get the label present on the amafans.eth domain
    / for example the label is graphicaldot then the subdomain present on the domain is graphicaldot.amafans.eth
    */
    function getLabel(address _address) 
                            view 
                            external 
                            returns(string memory) {
        bytes32 _requestId = results[_address].reqID;
        _verificationStarted(_requestId);
        if (isPending(_requestId) == true) {
            return results[_address].label ; 
        }
        return "";

    }
    
    function getEncodedData() 
                            view 
                            external 
                            returns(bytes memory) {
        bytes32 _requestId = results[msg.sender].reqID;
        _verificationStarted(_requestId);
        if (isPending(_requestId) == true) {
            return results[msg.sender].data; 
        }
        return "";
    }
    
    
    function _verificationStarted(bytes32 _requestId) pure private {
        require(_requestId != EMPTY_BYTES32, "Verification for this address hasnt been initiated yet");
        return;
    }
    
    function withdrawLink(address _address) 
            public 
            onlyRole(GOVERNANCE_ROLE) {
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        require(_link.transfer(_address, _link.balanceOf(address(this))), "Unable to transfer");
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
    function deleteVerification(address _ethaddress) external onlyRole(GOVERNANCE_ROLE)  {

        delete results[_ethaddress];
    }
    

}


    