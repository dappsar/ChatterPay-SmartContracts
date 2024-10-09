// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

error BeaconAccessor__WithdrawFailed();

contract BeaconAccessor is Ownable {
    IBeacon public beacon;

    constructor(address _beacon) Ownable(msg.sender) {
        beacon = IBeacon(_beacon);
    }

    function implementation() external view returns (address) {
        return beacon.implementation();
    }

    function updateBeacon(address _newBeacon) external onlyOwner {
        beacon = IBeacon(_newBeacon);
    }

    function execute(
        address dest,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        (bool success, ) = dest.call{value: value}(data);
        if (!success) {
            revert("ChatterPayPaymaster: execution failed");
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert BeaconAccessor__WithdrawFailed();
    }

    receive() external payable {}
}
