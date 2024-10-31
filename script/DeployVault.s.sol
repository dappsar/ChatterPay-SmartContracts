// DeployChatterPayVault.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/L2/ChatterPayVault.sol";

contract DeployChatterPayVault is Script {
    function run() external {
        vm.startBroadcast();

        ChatterPayVault chatterPayVault = new ChatterPayVault();

        console.log("ChatterPayVault deployed to:", address(chatterPayVault));

        vm.stopBroadcast();
    }
}