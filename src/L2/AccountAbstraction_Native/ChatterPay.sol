// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ChatterPay is Initializable {
  function initialize(address owner) public initializer {}
}




















// interface IL1Blocks {
//     function latestBlockNumber() external view returns (uint256);
// }

// address constant L1_BLOCKS_ADDRESS = 0x5300000000000000000000000000000000000001;
// address constant L1_SLOAD_ADDRESS = 0x0000000000000000000000000000000000000101;
// uint256 constant NUMBER_SLOT = 0;
// address immutable l1StorageAddr;

// constructor(address _l1Storage) {
//     l1StorageAddr = _l1Storage;
// }

// function latestL1BlockNumber() public view returns (uint256) {
//     uint256 l1BlockNum = IL1Blocks(L1_BLOCKS_ADDRESS).latestBlockNumber();
//     return l1BlockNum;
// }

// function retrieveFromL1() public view returns(uint) {
//     bytes memory input = abi.encodePacked(l1StorageAddr, NUMBER_SLOT);
//     bool success;
//     bytes memory ret;
//     (success, ret) = L1_SLOAD_ADDRESS.staticcall(input);
//     if (!success) {
//         revert("L1SLOAD failed");
//     }
//     return abi.decode(ret, (uint256));
// }
