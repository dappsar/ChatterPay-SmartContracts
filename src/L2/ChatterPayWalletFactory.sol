// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ChatterPayBeacon} from "./ChatterPayBeacon.sol";
import {ChatterPay} from "./ChatterPay.sol";
import {console} from "lib/forge-std/src/Console.sol";

contract ChatterPayWalletFactory is Ownable {
    address[] public proxies;
    address immutable entryPoint;
    address public immutable beacon;

    event ProxyCreated(address indexed owner, address proxyAddress);

    constructor(address _beacon, address _entryPoint, address _owner) Ownable(_owner) {
        beacon = _beacon;
        entryPoint = _entryPoint;
    }

    function createProxy(address _owner) public returns (address) {
        BeaconProxy walletProxy = new BeaconProxy{
            salt: bytes32(bytes20(_owner))
        }(
            beacon,
            abi.encodeWithSelector(
                ChatterPay.initialize.selector,
                entryPoint,
                _owner
            )
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(_owner, address(walletProxy));
        return address(walletProxy);
    }

    function getProxyOwner(address proxy) public returns (bytes memory) {
        (bool success, bytes memory data) = proxy.call(abi.encodeWithSignature("owner()"));
        return data;
    }

    function computeProxyAddress(address _owner) public view returns (address) {
        bytes memory bytecode = getProxyBytecode(_owner);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(bytes20(_owner)),
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getProxyBytecode(address _owner) internal view returns (bytes memory) {
        bytes memory initializationCode = abi.encodeWithSelector(
            ChatterPay.initialize.selector,
            entryPoint,
            _owner
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
