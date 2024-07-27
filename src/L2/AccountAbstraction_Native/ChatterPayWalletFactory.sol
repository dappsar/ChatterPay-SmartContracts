// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {ChatterPayBeacon} from "./ChatterPayBeacon.sol";
import {ChatterPay} from "./ChatterPay.sol";

contract ChatterPayWalletFactory {
    address[] public proxies;
    address public immutable beacon;

    event ProxyCreated(address indexed owner, address proxyAddress);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function createProxy(address owner) public returns (address) {
        BeaconProxy walletProxy = new BeaconProxy(
            beacon,
            abi.encodeWithSelector(ChatterPay.initialize.selector, owner)
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(owner, address(walletProxy));
        return address(walletProxy);
    }

    function getProxies() public view returns (address[] memory) {
        return proxies;
    }
}
