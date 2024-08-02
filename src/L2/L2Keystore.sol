// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL1Keystore} from "../Ethereum/L1Keystore.sol";

interface IL2Messenger {
  function sendMessage(address target, uint256 gasLimit, bytes calldata message) external;
}

contract L2Keystore {

  address immutable l1Keystore;
  address immutable l2Messenger;
  address constant L1_BLOCKS_ADDRESS = 0x5300000000000000000000000000000000000001; // Scroll Devnet Only!
  address constant L1_SLOAD_ADDRESS = 0x0000000000000000000000000000000000000101; // Scroll Devnet Only!
  bytes32 constant _SALT_KEY = keccak256("_SALT_KEY");
  bytes32 constant _UPDATE_KEY_GAS_LIMIT = keccak256("_UPDATE_KEY_GAS_LIMIT");
  bytes32 constant _WALLET_VERSION_KEY = keccak256("_WALLET_VERSION_KEY");
  bytes32 constant _WALLET_REGISTRY_SLOT = keccak256("_WALLET_REGISTRY_SLOT");
    
  modifier canWrite(address account) {
    require(msg.sender == account);
    _;
  }

  event WriteKey(address indexed account, bytes32 indexed key, bytes32 indexed value);
  event UpdateKey(address indexed account, bytes32 indexed key, bytes32 oldValue, bytes32 indexed newValue);

  constructor() {

  }
  
  function loadKey(address account, bytes32 key) public returns (bytes32) {
    bytes32 slot = _computeKeySlot(account, key);
    // l1Sload is a new precompile that allows the smart contract to trustlessly read a storage slot from L1 state root without a merkle proof.
    return l1Sload(l1Keystore, slot);
  }

  function l1Sload(address addr, bytes32 slot) public returns (bytes32) {
    // bytes memory data = abi.encodeWithSelector(bytes4(keccak256("sload(bytes32)")), slot);
    // (bool success, bytes memory returnData) = addr.call(data);
    // require(success, "L2Keystore::l1Sload: failed");
    // return abi.decode(returnData, (bytes32));
  }

  function writeKey(address account, bytes32 key, bytes32 value) public canWrite(account) {
    require(loadKey(account, key) == 0);
    bytes memory _message = abi.encodeWithSignature("writeKey(address,bytes32,bytes32)", account, key, value);
    // l2Messenger.sendMessage(l1Keystore, 0, _message, _WRITE_KEY_GAS_LIMIT);
    emit WriteKey(account, key, value);
  }
  
  function updateKey(address account, bytes32 key, bytes32 oldValue, bytes32 newValue) public canWrite(account) {
    require(key != _SALT_KEY);
    require(loadKey(account, key) == oldValue);
    bytes memory _message = abi.encodeWithSignature("updateKey(address,bytes32,bytes32,bytes32)", account, key, oldValue, newValue);
    IL2Messenger(l2Messenger).sendMessage(l1Keystore, 0, _message);
    emit UpdateKey(account, key, oldValue, newValue);
  }
  
  function getWalletImplementation(address account) public returns (address) {
    bytes32 walletVersion; // = keyStorage[account][_WALLET_VERSION_KEY];
    bytes32 slot = keccak256(abi.encodePacked(walletVersion, block.chainid, _WALLET_REGISTRY_SLOT));
    address impl = address(bytes20(l1Sload(l1Keystore, slot)));
    require(impl != address(0), "implementation is not registered");
    return impl;
  }

  function _computeKeySlot(address account, bytes32 key) internal view returns (bytes32) {
    // ...
  }
}