// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/ChatterPay.sol";
import {ChatterPayBeacon} from "../src/L2/ChatterPayBeacon.sol";
import {ChatterPayWalletFactory} from "../src/L2/ChatterPayWalletFactory.sol";
import {L1Keystore} from "../src/Ethereum/L1Keystore.sol";
import {L2Keystore} from "../src/L2/L2Keystore.sol";
import {TokensPriceFeeds} from "../src/Ethereum/TokensPriceFeeds.sol";
import {ChatterPayNFT} from "../src/L2/ChatterPayNFT.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract DeployChatterPay_EntryPoint is Script {
    uint256 ethSepoliaChainId = 11155111;
    uint256 scrollSepoliaChainId = 534351;
    uint256 scrollDevnetChainId = 2227728;

    HelperConfig helperConfig;
    ChatterPay chatterPay;
    ChatterPayBeacon beacon;
    ChatterPayWalletFactory factory;
    // L1Keystore l1Keystore;
    // L2Keystore l2Keystore;
    TokensPriceFeeds tokensPriceFeeds;
    ChatterPayNFT chatterPayNFT;

    function run() public {
        deployChatterPayOnL2();
    }

    function deployChatterPayOnL2()
        public
        returns (
            HelperConfig,
            ChatterPay,
            ChatterPayBeacon,
            ChatterPayWalletFactory,
            TokensPriceFeeds,
            ChatterPayNFT
        )
    {
        // Deploy HelperConfig
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        console.log(
            "Deploying ChatterPay contracts in chainId %s with account: %s",
            block.chainid,
            config.account
        );

        // Deploy Logic
        // CREATE2 for production
        // chatterPay = new ChatterPay{
        //     salt: keccak256(abi.encodePacked(config.account))
        // }();
        chatterPay = new ChatterPay();
        console.log("ChatterPay deployed to address %s", address(chatterPay));

        // Deploy Beacon (with Logic address as parameter)
        // CREATE2 for production
        // beacon = new ChatterPayBeacon{
        //     salt: keccak256(abi.encodePacked(config.account))
        // }(address(chatterPay), config.account);
        beacon = new ChatterPayBeacon(address(chatterPay), config.account);
        console.log("ChatterPayBeacon deployed to address %s", address(beacon));

        address paymaster = address(1); // TBD - Paymaster Address

        // Deploy Factory (with Beacon, EntryPoint, Account & Paymaster addresses as parameters)
        // CREATE2 for production
        // factory = new ChatterPayWalletFactory{
        //     salt: keccak256(abi.encodePacked(config.account))
        // }(address(beacon), config.entryPoint, config.account, paymaster);
        factory = new ChatterPayWalletFactory(address(beacon), config.entryPoint, config.account, paymaster);
        console.log(
            "ChatterPayWalletFactory deployed to address %s",
            address(factory)
        );

        chatterPay.initialize(
            config.entryPoint,
            config.account,
            paymaster
        );
        console.log("ChatterPay initialized");

        // Deploy ChatterPayNFT
        chatterPayNFT = new ChatterPayNFT(config.account);
        console.log(
            "ChatterPayNFT deployed to address %s",
            address(chatterPayNFT)
        );

        vm.stopBroadcast();

        return (
            helperConfig,
            chatterPay,
            beacon,
            factory,
            tokensPriceFeeds,
            chatterPayNFT
        );
    }
}
