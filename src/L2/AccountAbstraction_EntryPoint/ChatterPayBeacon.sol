// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract ChatterPayBeacon is UpgradeableBeacon {
    
    constructor(
        address _initChatterPayImplementation
    ) UpgradeableBeacon(_initChatterPayImplementation, msg.sender) {}

    function update(address _newChatterPayImplementation) public onlyOwner {
        this.upgradeTo(_newChatterPayImplementation);
    }
}
