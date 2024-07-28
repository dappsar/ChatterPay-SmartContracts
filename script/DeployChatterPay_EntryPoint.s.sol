// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPay.sol";
import {ChatterPayBeacon} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPayBeacon.sol";
import {ChatterPayWalletFactory} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPayWalletFactory.sol";

contract DeployChatterPay_EntryPoint is Script {

  function run() public {
    deployChatterPay();
  }

  function deployChatterPay() public returns (HelperConfig, ChatterPay, ChatterPayBeacon, ChatterPayWalletFactory) {
    // Deploy HelperConfig
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    
    vm.startBroadcast(config.account);
    // Deploy Logic
    ChatterPay chatterPay = new ChatterPay();
    // Deploy Beacon (with Logic address)
    ChatterPayBeacon beacon = new ChatterPayBeacon(address(chatterPay));
    // Deploy Factory (with Beacon & EntryPoint address)
    ChatterPayWalletFactory factory = new ChatterPayWalletFactory(address(beacon), config.entryPoint);
    vm.stopBroadcast();

    return (helperConfig, chatterPay, beacon, factory);
  }

}