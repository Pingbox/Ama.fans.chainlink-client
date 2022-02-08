//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Test{
        mapping(bytes32 => address) public usernameToAddress;



    function keccakHash(string memory _string)  public pure returns (bytes32){
        return keccak256(abi.encodePacked(_string));
    }

    function getUsernameToAddress(string memory username)
        external 
        view
        returns (address) {
            return usernameToAddress[ keccakHash(username)];


        }

    function callt(string memory username)
        external {

        usernameToAddress[keccakHash(username)] = msg.sender;
    }

         function decodeData(bytes memory _bytes) 
            public
            pure 
            returns(string memory, string memory, string memory, uint256, bool) {
        (string memory username, 
        string memory name, 
        string memory profileImage,
        uint256 id,
        bool twitterVerified) = abi.decode(_bytes, (string,string,string,uint256,bool));
            return (username, name, profileImage, id, twitterVerified);

            }
}