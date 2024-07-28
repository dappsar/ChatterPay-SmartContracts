// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChatterPayBeacon is Ownable {
    UpgradeableBeacon immutable beacon;

    address public chatterPayimplementation;

    constructor(address _initChatterPayImplementation) Ownable(msg.sender) {
        beacon = new UpgradeableBeacon(
            _initChatterPayImplementation,
            msg.sender
        );
        chatterPayimplementation = _initChatterPayImplementation;
    }

    function update(address _newChatterPayImplementation) public onlyOwner {
        beacon.upgradeTo(_newChatterPayImplementation);
    }

    function implementation() public view returns (address){
        return beacon.implementation();
    }
}
