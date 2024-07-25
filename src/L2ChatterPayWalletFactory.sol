// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ChatterPayWallet} from "./L2ChatterPayWallet.sol";
import {ChatterPayBeacon} from "./L2ChatterPayBeacon.sol";

contract ChatterPayWalletFactory {
    
    address[] public wallets;
    address public immutable beacon;

    event WalletCreated(address indexed owner, address walletAddress);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function createWallet(address owner) public returns (address) {
        ChatterPayWallet wallet = new ChatterPayWallet(beacon);
        wallets.push(address(wallet));
        emit WalletCreated(owner, address(wallet));
        return address(wallet);
    }

    function getWallets() public view returns (address[] memory) {
        return wallets;
    }
}
