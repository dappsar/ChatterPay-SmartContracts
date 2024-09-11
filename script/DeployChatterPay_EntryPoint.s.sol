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
    L1Keystore l1Keystore;
    L2Keystore l2Keystore;
    TokensPriceFeeds tokensPriceFeeds;
    ChatterPayNFT chatterPayNFT;

    function run() public {
        deployChatterPayOnL2();
        deployL1Keystore();
    }

    function deployL1Keystore() public returns (L1Keystore) {
        if (block.chainid == ethSepoliaChainId) {
            // Deploy L1Keystore if chain is Eth Sepolia
            address factoryAddress = DevOpsTools.get_most_recent_deployment(
                "ChatterPayWalletFactory",
                scrollDevnetChainId
            );
            l1Keystore = new L1Keystore(factoryAddress);
            console.log(
                "L1Keystore deployed to address %s",
                address(l1Keystore)
            );
        }
        return l1Keystore;
    }

    function deployChatterPayOnL2()
        public
        returns (
            HelperConfig,
            ChatterPay,
            ChatterPayBeacon,
            ChatterPayWalletFactory,
            L2Keystore,
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

        l2Keystore = new L2Keystore(address(l1Keystore), address(0));
        console.log("L2Keystore deployed to address %s", address(l2Keystore));
        if (address(l1Keystore) != address(0)) {
            factory.setKeystore(address(l1Keystore), address(l2Keystore));
            console.log("Keystore addresses set in factory");
        } else {
            console.log("Keystore addresses NOT set in factory");
        }

        chatterPay.initialize(
            config.entryPoint,
            config.account,
            address(l1Keystore),
            address(l2Keystore),
            paymaster
        );
        console.log("ChatterPay initialized");

        // Deploy ChatterPayNFT
        chatterPayNFT = new ChatterPayNFT(config.account);
        console.log(
            "ChatterPayNFT deployed to address %s",
            address(chatterPayNFT)
        );

        if (block.chainid == scrollSepoliaChainId) {
            // For Scroll Sepolia
            // Deploy API3 Price feed
            address ETH_USD_FEED = 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1;
            address BTC_USD_FEED = 0x81A64473D102b38eDcf35A7675654768D11d7e24;
            tokensPriceFeeds = new TokensPriceFeeds(ETH_USD_FEED, BTC_USD_FEED);
            console.log(
                "TokensPriceFeeds deployed to address %s",
                address(tokensPriceFeeds)
            );
        }

        vm.stopBroadcast();

        return (
            helperConfig,
            chatterPay,
            beacon,
            factory,
            l2Keystore,
            tokensPriceFeeds,
            chatterPayNFT
        );
    }
}
