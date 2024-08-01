// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BeaconProxy} from "lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ChatterPayBeacon} from "./ChatterPayBeacon.sol";
import {ChatterPay} from "./ChatterPay.sol";
import {console} from "lib/forge-std/src/Console.sol";

interface IChatterPayWalletFactory {
    function createProxy(address _owner) external returns (address);
    function getProxyOwner(address proxy) external returns (bytes memory);
    function computeProxyAddress(address _owner) external view returns (address);
    function getProxies() external view returns (address[] memory);
    function getProxiesCount() external view returns (uint256);
}

contract ChatterPayWalletFactory is Ownable, IChatterPayWalletFactory {
    address[] public proxies;
    address immutable entryPoint;
    address public immutable beacon;
    address immutable l1Storage;

    event ProxyCreated(address indexed owner, address proxyAddress);

    constructor(address _beacon, address _entryPoint, address _owner, address _l1Storage) Ownable(_owner) {
        beacon = _beacon;
        entryPoint = _entryPoint;
        l1Storage = _l1Storage;
    }

    function createProxy(address _owner) public returns (address) {
        BeaconProxy walletProxy = new BeaconProxy{
            salt: keccak256(abi.encodePacked(_owner))
        }(
            beacon,
            abi.encodeWithSelector(
                ChatterPay.initialize.selector,
                entryPoint,
                _owner,
                l1Storage
            )
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(_owner, address(walletProxy));
        return address(walletProxy);
    }

    function getProxyOwner(address proxy) public returns (bytes memory) {
        (, bytes memory data) = proxy.call(abi.encodeWithSignature("owner()"));
        return data;
    }

    function computeProxyAddress(address _owner) public view returns (address) {
        bytes memory bytecode = getProxyBytecode(_owner);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                keccak256(abi.encodePacked(_owner)),
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getProxyBytecode(address _owner) internal view returns (bytes memory) {
        bytes memory initializationCode = abi.encodeWithSelector(
            ChatterPay.initialize.selector,
            entryPoint,
            _owner,
            l1Storage
        );
        return abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(beacon, initializationCode)
        );
    }

    function getProxies() public view returns (address[] memory) {
        return proxies;
    }

    function getProxiesCount() public view returns (uint256) {
        return proxies.length;
    }
}
