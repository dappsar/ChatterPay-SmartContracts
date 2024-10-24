// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {UpgradeableBeacon} from "lib/openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract ChatterPayBeacon is UpgradeableBeacon {
    
    constructor(
        address _initChatterPayImplementation,
        address _owner
    ) UpgradeableBeacon(_initChatterPayImplementation, _owner) {}

    function update(address _newChatterPayImplementation) public onlyOwner {
        this.upgradeTo(_newChatterPayImplementation);
    }
}
