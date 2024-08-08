// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {IL1Keystore} from "../Ethereum/L1Keystore.sol";
import {console} from "forge-std/console.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface IL2Messenger {
  function sendMessage(address target, uint256 gasLimit, bytes calldata message) external;
}

interface IL1Blocks {
    function latestBlockNumber() external view returns (uint256);
}

interface IL2Keystore {
  function l1SloadGetWalletOwner(address wallet) external view returns (address);
}

/*//////////////////////////////////////////////////////////////
                            CONTRACT
//////////////////////////////////////////////////////////////*/

contract L2Keystore {

  /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

  address immutable l1Keystore;
  address immutable l2Messenger;
  address constant L1_BLOCKS_ADDRESS = 0x5300000000000000000000000000000000000001; // Scroll Devnet Only!
  address constant L1_SLOAD_ADDRESS = 0x0000000000000000000000000000000000000101; // Scroll Devnet Only!
  bytes32 constant _SALT_KEY = keccak256("_SALT_KEY");
  bytes32 constant _UPDATE_KEY_GAS_LIMIT = keccak256("_UPDATE_KEY_GAS_LIMIT");
  bytes32 constant _WALLET_VERSION_KEY = keccak256("_WALLET_VERSION_KEY");
  bytes32 constant _WALLET_REGISTRY_SLOT = keccak256("_WALLET_REGISTRY_SLOT");

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/
    
  modifier canWrite(address account) {
    require(msg.sender == account);
    _;
  }

  /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  event WriteKey(address indexed account, bytes32 indexed key, bytes32 indexed value);
  event UpdateKey(address indexed account, bytes32 indexed key, bytes32 oldValue, bytes32 indexed newValue);

  /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  constructor(address _l1Keystore, address _l2Messenger) {
    l1Keystore = _l1Keystore;
    l2Messenger = _l2Messenger;
  }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function l1SloadGetWalletOwner(address wallet) public view returns (address) {
    uint256 slot = _computeOwnerSlot(wallet);
    bytes memory input = abi.encodePacked(l1Keystore, slot);
    bool success;
    bytes memory ret;
    (success, ret) = L1_SLOAD_ADDRESS.staticcall(input);
    if (!success) {
        revert("L1SLOAD failed");
    }
    return abi.decode(ret, (address));
  }

  /*//////////////////////////////////////////////////////////////
                      VIEW AND PURE FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function getlatestL1BlockNumber() public view returns (uint256) {
      uint256 l1BlockNum = IL1Blocks(L1_BLOCKS_ADDRESS).latestBlockNumber();
      return l1BlockNum;
  }

  function _computeOwnerSlot(address wallet) public pure returns (uint256) { // chante to internal after tests
    uint256 slotOfMapping = 0; // Slot of the mapping accounts
    bytes32 mappingSlot = keccak256(abi.encode(wallet, slotOfMapping));
    return uint256(mappingSlot);
  }

  function _computeKeySlot(address account, bytes32 key) internal pure returns (bytes32) {}
}


// function loadKey(address account, bytes32 key) public returns (address) {
//   bytes32 slot = _computeKeySlot(account, key);
//   return l1Sload(l1Keystore, slot);
// }

// function writeKey(address account, bytes32 key, bytes32 value) public canWrite(account) {
//   require(loadKey(account, key) == address(0));
//   bytes memory _message = abi.encodeWithSignature("writeKey(address,bytes32,bytes32)", account, key, value);
//   // l2Messenger.sendMessage(l1Keystore, 0, _message, _WRITE_KEY_GAS_LIMIT);
//   emit WriteKey(account, key, value);
// }

// function updateKey(address account, bytes32 key, bytes32 oldValue, bytes32 newValue) public canWrite(account) {
//   require(key != _SALT_KEY);
//   require(loadKey(account, key) == oldValue);
//   bytes memory _message = abi.encodeWithSignature("updateKey(address,bytes32,bytes32,bytes32)", account, key, oldValue, newValue);
//   IL2Messenger(l2Messenger).sendMessage(l1Keystore, 0, _message);
//   emit UpdateKey(account, key, oldValue, newValue);
// }

// function getWalletImplementation(address account) public returns (address) {
//   bytes32 walletVersion; // = keyStorage[account][_WALLET_VERSION_KEY];
//   bytes32 slot = keccak256(abi.encodePacked(walletVersion, block.chainid, _WALLET_REGISTRY_SLOT));
//   address impl = address(bytes20(l1Sload(l1Keystore, slot)));
//   require(impl != address(0), "implementation is not registered");
//   return impl;
// }