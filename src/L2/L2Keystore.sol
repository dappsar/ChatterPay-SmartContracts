// // L2 keystore contract
// contract L2Keystore {
//   immutable address l1Keystore;
//   immutable address l2Messenger;
    
//   uint256 constant _UPDATE_KEY_GAS_LIMIT = xx;
    
//   modifier canWrite(address account) {
//     require(msg.caller == account);
//   }
  
//   function registerAccount(
//       bytes32 salt, 
//       bytes32 walletId,
//       bytes32[] initKeys,
//       bytes32[] initValues,
//       bytes memory initdata, 
//       address l2Rollup
//   ) returns address {
//     revert("registerAccount is not supported on L2");
//   }
  
//   function loadKey(address account, bytes32 key) returns bytes32 {
//     bytes32 slot = _computeKeySlot(account, key);
//     // l1Sload is a new precompile that allows the smart contract to trustlessly read a storage slot from L1 state root without a merkle proof.
//     return l1Sload(l1Keystore, slot);
//   }

//   function writeKey(address account, bytes32 key, bytes value) canWrite(account) {
//     require(loadKey(account, key) == 0);
//     bytes _message = abi.encodeCall(IKeystore.writeKey, (account, key, value));
//     l2Messenger.sendMessage(l1Keystore, 0, _message, _WRITE_KEY_GAS_LIMIT);
//     emit WriteKey(account, key, value);
//   }
  
//   function updateKey(address account, bytes32 key, bytes oldValue, bytes32 newValue) canWrite(account) {
//     require(key != _SALT_SLOT);
//     require(loadKey(account, key) == oldValue);
//     bytes _message = abi.encodeCall(IKeystore.updateKey, (account, key, oldValue, newValue));
//     l2Messenger.sendMessage(l1Keystore, 0, _message, _UPDATE_KEY_GAS_LIMIT);
//     emit UpdateKey(account, key, oldValue, newValue);
//   }
  
//   function getWalletImplementation(address account) returns address {
//     bytes32 walletId = keyStorage[account][_WALLET_ID_KEY];
//     assembly {
//       let chainID := chainid();
//     }
//     bytes32 slot = keccak256(walletId . chainId . _WALLET_REGISTRY_SLOT);
//     address impl = address(l1Sload(l1Keystore, slot));
//     require(impl != 0, "implementation is not registered");
//     return impl;
//   }

//   function _computeKeySlot(address account, bytes32 key) internal view returns bytes32 {
//     // ...
//   }
// }