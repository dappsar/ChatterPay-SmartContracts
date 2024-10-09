// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ChatterPay} from "./ChatterPay.sol";

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
    address public walletImplementation;
    address public paymaster;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProxyCreated(address indexed owner, address indexed proxyAddress);
    event NewImplementation(address indexed _walletImplementation);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address _walletImplementation, address _entryPoint, address _owner, address _paymaster) Ownable(_owner) {
        walletImplementation = _walletImplementation;
        entryPoint = _entryPoint;
        paymaster = _paymaster;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createProxy(address _owner) public returns (address) {
        if(_owner == address(0)) revert ChatterPayWalletFactory__InvalidOwner();
        ERC1967Proxy walletProxy = new ERC1967Proxy{
            salt: keccak256(abi.encodePacked(_owner))
        }(
            walletImplementation,
            abi.encodeWithSelector(
                ChatterPay.initialize.selector,
                entryPoint,
                _owner,
                paymaster
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

    function setImplementationAddress(address _walletImplementation) public onlyOwner {
        walletImplementation = _walletImplementation;
        emit NewImplementation(_walletImplementation);
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
            paymaster
        );
        return abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(walletImplementation, initializationCode)
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
