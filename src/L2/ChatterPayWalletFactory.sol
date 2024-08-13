// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {BeaconProxy} from "lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ChatterPayBeacon} from "./ChatterPayBeacon.sol";
import {ChatterPay} from "./ChatterPay.sol";
import {console} from "lib/forge-std/src/console.sol";

/*//////////////////////////////////////////////////////////////
                                ERRORS
//////////////////////////////////////////////////////////////*/

error ChatterPayWalletFactory__InvalidOwner();

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface IChatterPayWalletFactory {
    function createProxy(address _owner) external returns (address);
    function getProxyOwner(address proxy) external returns (bytes memory);
    function computeProxyAddress(address _owner) external view returns (address);
    function getProxies() external view returns (address[] memory);
    function getProxiesCount() external view returns (uint256);
}

/*//////////////////////////////////////////////////////////////
                            CONTRACT
//////////////////////////////////////////////////////////////*/

contract ChatterPayWalletFactory is Ownable, IChatterPayWalletFactory {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] public proxies;
    address immutable entryPoint;
    address public immutable beacon;
    address public l1Storage;
    address public l2Storage;
    address public paymaster;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProxyCreated(address indexed owner, address indexed proxyAddress);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address _beacon, address _entryPoint, address _owner, address _paymaster) Ownable(_owner) {
        console.log("ChatterPayWalletFactory deployed with owner: %s", _owner);
        beacon = _beacon;
        entryPoint = _entryPoint;
        paymaster = _paymaster;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createProxy(address _owner) public returns (address) {
        if(_owner == address(0)) revert ChatterPayWalletFactory__InvalidOwner();
        BeaconProxy walletProxy = new BeaconProxy{
            salt: keccak256(abi.encodePacked(_owner))
        }(
            beacon,
            abi.encodeWithSelector(
                ChatterPay.initialize.selector,
                entryPoint,
                _owner,
                l1Storage,
                l2Storage,
                paymaster
            )
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(_owner, address(walletProxy));
        return address(walletProxy);
    }

    function setKeystore(address _l1Storage, address _l2Storage) public onlyOwner {
        l1Storage = _l1Storage;
        l2Storage = _l2Storage;
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

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getProxyBytecode(address _owner) internal view returns (bytes memory) {
        bytes memory initializationCode = abi.encodeWithSelector(
            ChatterPay.initialize.selector,
            entryPoint,
            _owner,
            l1Storage,
            l2Storage,
            paymaster
        );
        return abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(beacon, initializationCode)
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getProxies() public view returns (address[] memory) {
        return proxies;
    }

    function getProxiesCount() public view returns (uint256) {
        return proxies.length;
    }
}
