// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Keystore is Ownable {
  mapping(uint256 id => mapping(uint256 chainId => address wallet)) private userWallets;

  constructor() Ownable(msg.sender) {}
  
  function saveWallet(uint256 id, uint32 chainId, address wallet) public onlyOwner {
    userWallets[id][chainId] = wallet;
  }

  function getWallet(uint256 id, uint32 chainId) public view returns (address) {
    return userWallets[id][chainId];
  }

  function removeWallet(uint256 id, uint256 chainId) public onlyOwner {
    delete userWallets[id][chainId];
  }
}