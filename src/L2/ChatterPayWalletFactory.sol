// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ChatterPayBeacon} from "./ChatterPayBeacon.sol";
import {ChatterPay} from "./ChatterPay.sol";
import {console} from "forge-std/Console.sol";

contract ChatterPayWalletFactory is Ownable {
    address[] public proxies;
    address immutable entryPoint;
    address public immutable beacon;

    event ProxyCreated(address indexed owner, address proxyAddress);

    constructor(address _beacon, address _entryPoint) Ownable(msg.sender) {
        beacon = _beacon;
        entryPoint = _entryPoint;
    }

    function createProxy(address _owner) public onlyOwner returns (address) {
        BeaconProxy walletProxy = new BeaconProxy(
            beacon,
            abi.encodeWithSelector(ChatterPay.initialize.selector, entryPoint, _owner)
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(_owner, address(walletProxy));
        return address(walletProxy);
    }

    function getProxies() public view returns (address[] memory) {
        return proxies;
    }

    function getProxiesCount() public view returns (uint256) {
        return proxies.length;
    }
}
