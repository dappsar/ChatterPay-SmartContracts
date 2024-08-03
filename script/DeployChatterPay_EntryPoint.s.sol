// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/ChatterPay.sol";
import {ChatterPayBeacon} from "../src/L2/ChatterPayBeacon.sol";
import {ChatterPayWalletFactory} from "../src/L2/ChatterPayWalletFactory.sol";
import {L1Keystore} from "../src/Ethereum/L1Keystore.sol";
import {L2Keystore} from "../src/L2/L2Keystore.sol";

contract DeployChatterPay_EntryPoint is Script {

  function run() public {
    if(block.chainid == 11155111){
      deployMainnet();
    } else {
      deployChatterPayL2();
    }
  }

  function deployChatterPayL2() public returns (HelperConfig, ChatterPay, ChatterPayBeacon, ChatterPayWalletFactory, L1Keystore, L2Keystore){
    // Deploy HelperConfig
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    
    vm.startBroadcast(config.account);
    console.log("Deploying ChatterPay contracts in chainId %s with account: %s", block.chainid, config.account);
    
    // Deploy Logic
    ChatterPay chatterPay = new ChatterPay{salt: keccak256(abi.encodePacked(config.account))}();
    address l1Storage; // TBD - L1 Keystore Address
    address paymaster = address(1); // TBD - Paymaster Address
    chatterPay.initialize(config.entryPoint, config.account, l1Storage, paymaster);
    console.log("ChatterPay deployed to address %s", address(chatterPay));
    
    // Deploy Beacon (with Logic address)
    ChatterPayBeacon beacon = new ChatterPayBeacon{salt: keccak256(abi.encodePacked(config.account))}(address(chatterPay), config.account);
    console.log("ChatterPayBeacon deployed to address %s", address(beacon));
    
    // Deploy Factory (with Beacon & EntryPoint address)
    ChatterPayWalletFactory factory = new ChatterPayWalletFactory{salt: keccak256(abi.encodePacked(config.account))}(address(beacon), config.entryPoint, config.account, l1Storage, paymaster);
    console.log("ChatterPayWalletFactory deployed to address %s", address(factory));

    // Deploy L1Keystore & L2Keystore
    L1Keystore l1Keystore = new L1Keystore(address(factory));
    console.log("L1Keystore deployed to address %s", address(l1Keystore));
    L2Keystore l2Keystore = new L2Keystore(address(l1Keystore), address(0));
    console.log("L2Keystore deployed to address %s", address(l2Keystore));
    
    vm.stopBroadcast();


    return (helperConfig, chatterPay, beacon, factory, l1Keystore, l2Keystore);
  }

  function deployMainnet() public returns (L1Keystore){
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    address factory;
    
    vm.startBroadcast(config.account);
    console.log("Deploying ChatterPay contracts in chainId %s with account: %s", block.chainid, config.account);

    // Deploy L1Keystore & L2Keystore
    L1Keystore l1Keystore = new L1Keystore(address(factory));
    console.log("L1Keystore deployed to address %s", address(l1Keystore));

    vm.stopBroadcast();
    return l1Keystore;
  }

}