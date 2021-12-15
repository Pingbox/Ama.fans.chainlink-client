
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Operator.sol: 0xE5163933000d785ba7d628AEbefc8B20C401F73D
//ProxyAdmin: 0x6f74B75f1d3c34DCAEf8209B551479D059e30550
//AMAClient: 0x2b7bc4D264082F5a45f69d1aFf450eF81795F884
//AMAClient proxy: 0xc6928b39dc5cd754d511Ac87879a19A20aD23161

contract Test{
    /*
   * @dev Reverts if the first 32 bytes of the bytes array is not equal to requestId
   * @param requestId bytes32
   * @param data bytes
   */
  modifier validateMultiWordResponseId(
    bytes32 requestId,
    bytes memory data
  ) {
    bytes32 firstWord;
    assembly{
      firstWord := mload(add(data, 0x20))
    }
    require(requestId == firstWord, "First word must be requestId");
    _;
  }
  
  function fulfillOracleRequest2(
    bytes32 requestId,
    bytes calldata data
  )
    external
    validateMultiWordResponseId(requestId, data)
    {

  }
  }