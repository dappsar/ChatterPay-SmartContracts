// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChatterPayBeacon is Ownable {
    UpgradeableBeacon immutable beacon;
    address public chatterPayImp;

    constructor(address _initChatterPayImp) Ownable(msg.sender) {
        beacon = new UpgradeableBeacon(
            _initChatterPayImp,
            msg.sender
        );
        chatterPayImp = _initChatterPayImp;
        transferOwnership(tx.origin);
    }

    function update(address _newChatterPayImp) public onlyOwner {
        beacon.upgradeTo(_newChatterPayImp);
        chatterPayImp = _newChatterPayImp;
    }

    function implementation() public view returns (address){
        return beacon.implementation();
    }
}
