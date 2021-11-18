
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IAmaENSClient {
    
    function renew(string calldata name, uint _duration) external;
    function registerNode(address _owner, bytes memory _bytes, string memory twitterUsername) external returns (bytes32, string memory);
    function getNodeHash(string memory _label) external view returns (bytes32,bytes32,uint256);

}