// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ChatterPayWalletProxy} from "./ChatterPayWalletProxy.sol";

/*//////////////////////////////////////////////////////////////
                                ERRORS
//////////////////////////////////////////////////////////////*/

error ChatterPayWalletFactory__ProxyAlreadyExists();
error ChatterPayWalletFactory__InvalidOwner();

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface IProxy {
    function owner() external view returns (address);
}

interface IChatterPayWalletFactory {
    function createProxy(address _owner) external returns (address);

    function getProxyOwner(address proxy) external returns (address);

    function computeProxyAddress(
        address _owner
    ) external view returns (address);

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

    address public walletImplementation;
    address immutable entryPoint;
    address public immutable paymaster;
    address[] private proxies;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProxyCreated(address indexed owner, address indexed proxyAddress);
    event NewImplementation(address indexed _walletImplementation);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        address _walletImplementation,
        address _entryPoint,
        address _paymaster
    ) Ownable(_owner) {
        walletImplementation = _walletImplementation;
        entryPoint = _entryPoint;
        paymaster = _paymaster;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createProxy(address _owner) public returns (address) {
        if (_owner == address(0))
            revert ChatterPayWalletFactory__InvalidOwner();
        address computedAddress = computeProxyAddress(_owner);
        if (computedAddress.code.length > 0) {
            revert ChatterPayWalletFactory__ProxyAlreadyExists();
        }
        ChatterPayWalletProxy walletProxy = new ChatterPayWalletProxy{
            salt: keccak256(abi.encodePacked(_owner))
        }(
            walletImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                entryPoint,
                _owner
            )
        );
        proxies.push(address(walletProxy));
        emit ProxyCreated(_owner, address(walletProxy));
        return address(walletProxy);
    }

    function setImplementationAddress(
        address _walletImplementation
    ) public onlyOwner {
        walletImplementation = _walletImplementation;
        emit NewImplementation(_walletImplementation);
    }

    function computeProxyAddress(address _owner) public view returns (address) {
        // Compute the salt using the owner's address
        bytes32 salt = keccak256(abi.encodePacked(_owner));
        // Get the bytecode of the proxy contract
        bytes memory bytecode = getProxyBytecode(_owner);
        // Compute the address using CREATE2 formula
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getProxyBytecode(
        address _owner
    ) internal view returns (bytes memory) {
        bytes memory initializationCode = abi.encodeWithSignature(
            "initialize(address,address)",
            entryPoint,
            _owner
        );
        return
            abi.encodePacked(
                type(ChatterPayWalletProxy).creationCode,
                abi.encode(walletImplementation, initializationCode)
            );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getProxyOwner(address proxy) public view returns (address) {
        return IProxy(proxy).owner();
    }

    function getProxies() public view returns (address[] memory) {
        return proxies;
    }

    function getProxiesCount() public view returns (uint256) {
        return proxies.length;
    }
}
