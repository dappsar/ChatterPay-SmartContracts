// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract ChatterPayWallet is BeaconProxy {
  constructor(address _beacon) BeaconProxy(_beacon, "") {}
  
}