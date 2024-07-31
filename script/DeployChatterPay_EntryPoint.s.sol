// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/ChatterPay.sol";
import {ChatterPayBeacon} from "../src/L2/ChatterPayBeacon.sol";
import {ChatterPayWalletFactory} from "../src/L2/ChatterPayWalletFactory.sol";

contract DeployChatterPay_EntryPoint is Script {

  function run() public {
    deployChatterPay();
  }

  function deployChatterPay() public returns (HelperConfig, ChatterPay, ChatterPayBeacon, ChatterPayWalletFactory) {
    // Deploy HelperConfig
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    
    vm.startBroadcast(config.account);
    console.log("Deploying ChatterPay contracts in chainId %s with account: %s", block.chainid, config.account);
    
    // Deploy Logic
    ChatterPay chatterPay = new ChatterPay{salt: bytes32(bytes20(config.account))}();
    chatterPay.initialize(config.entryPoint, config.account);
    console.log("ChatterPay deployed to address %s", address(chatterPay));
    
    // Deploy Beacon (with Logic address)
    ChatterPayBeacon beacon = new ChatterPayBeacon{salt: bytes32(bytes20(config.account))}(address(chatterPay), config.account);
    console.log("ChatterPayBeacon deployed to address %s", address(beacon));
    
    // Deploy Factory (with Beacon & EntryPoint address)
    ChatterPayWalletFactory factory = new ChatterPayWalletFactory{salt: bytes32(bytes20(config.account))}(address(beacon), config.entryPoint, config.account);
    console.log("ChatterPayWalletFactory deployed to address %s", address(factory));
    vm.stopBroadcast();

    return (helperConfig, chatterPay, beacon, factory);
  }

}