// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IChatterPayWalletFactory} from "../L2/ChatterPayWalletFactory.sol";

error L1Keystore__NotAuthorized();
error L1Keystore__InvalidSalt();
error L1Keystore__InvalidInitData();
error L1Keystore__InvalidWalletVersion();
error L1Keystore__AccountAlreadyExisted();
error L1Keystore__KeyAlreadyExisted();
error L1Keystore__InvalidKey();
error L1Keystore__InvalidOldValue();
error L1Keystore__WalletAlreadyRegistered();
error L1Keystore__ImplementationNotRegistered();

interface IL1Keystore {
  function writeKey(address account, bytes32 key, bytes32 value) external;
  function updateKey(address account, bytes32 key, bytes32 oldValue, bytes32 newValue) external;
}

contract L1Keystore is IL1Keystore {
  
  struct WalletEntry {
    address owner;
    // mapping from chain id to implementation address
    mapping(uint256 chainId => address implementation) implementations;
  }
    
  struct UserAccount {
    // EOA owner of this SCW account
    address owner;
    // key-value map storage
    mapping(bytes32 key => bytes32 value) keys;
    // a L2 rollup contract that can update this account
    address l2KeyUpdate;
    // The user's phone number
    string userId;
  }

  /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

  // mapping from AA wallet addr to user account storage
  mapping(address wallet => UserAccount) accounts;
  // mapping from wallet version to wallet registration entry
  mapping(bytes32 walletVersion => WalletEntry) walletRegistry;

  IChatterPayWalletFactory walletFactory;
  
  // Reserved keys
  bytes32 constant _SALT_KEY = keccak256("_SALT_KEY");
  bytes32 constant _WALLET_VERSION_KEY = keccak256("_WALLET_VERSION_KEY");
  bytes32 constant _INITDATA_HASH_KEY = keccak256("_INITDATA_HASH_KEY");
  bytes32 constant _L2_UPDATE_ADDRESS = keccak256("_L2_UPDATE_ADDRESS");

  /*//////////////////////////////////////////////////////////////
                               MODIFIERS
  //////////////////////////////////////////////////////////////*/
  
  modifier canWrite(address account) {
    if(msg.sender != account && msg.sender != accounts[account].l2KeyUpdate) {
      revert L1Keystore__NotAuthorized();
    }
    _;
  }

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
  //////////////////////////////////////////////////////////////*/
  
  event WalletRegistered(bytes32 _walletVersion, address indexed _owner, uint256 indexed _chainId, address indexed _implementation);
  event AccountRegistered(address indexed addr, address indexed _owner, bytes32 indexed walletVersion);
  event KeyStored(address indexed account, bytes32 indexed key, bytes32 indexed value);
  event KeyUpdated(address indexed account, bytes32 key, bytes32 oldValue, bytes32 newValue);
  event AccessUpdated(address indexed account, address indexed oldUpdateContract, address indexed newUpdateContract);

  /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  constructor(address _accountFactory) {
    walletFactory = IChatterPayWalletFactory(_accountFactory);
  }

  function registerAccount(
      address _owner,
      bytes32 salt,
      bytes32 walletVersion,
      bytes32[] memory initKeys,
      bytes32[] memory initValues,
      bytes memory initdata, 
      address l2Rollup,
      string memory _userId
  ) public returns (address) {
    // validate inputs
    if(salt == 0) revert L1Keystore__InvalidSalt();
    if(initKeys.length != initValues.length) revert L1Keystore__InvalidInitData();
    if(walletRegistry[walletVersion].owner == address(0)) revert L1Keystore__InvalidWalletVersion();
    
    address addr = walletFactory.computeProxyAddress(_owner);

    if(accounts[addr].keys[_SALT_KEY] != bytes32(0)) revert L1Keystore__AccountAlreadyExisted();
    // Write the special keys
    accounts[addr].owner = _owner;
    accounts[addr].userId = _userId;
    accounts[addr].keys[_SALT_KEY] = salt;
    accounts[addr].keys[_WALLET_VERSION_KEY] = walletVersion;
    accounts[addr].keys[_INITDATA_HASH_KEY] = keccak256(initdata);
    if(initKeys.length > 0){
      // Write the initial keys
      for (uint i; i < initKeys.length; i++) {
        accounts[addr].keys[initKeys[i]] = initValues[i];
      } 
    }
    // If specified, allow a L2 chain to update the keys for this account
    if (l2Rollup != address(0)) {
      accounts[addr].l2KeyUpdate = l2Rollup;
    }
    emit AccountRegistered(addr, _owner, walletVersion);
    return addr;
  }
  
  function writeKey(address account, bytes32 key, bytes32 value) public canWrite(account) {  
    if(accounts[account].keys[key] != bytes32(0)) revert L1Keystore__KeyAlreadyExisted();
    accounts[account].keys[key] = value;
    emit KeyStored(account, key, value);
  }

  function updateKey(address account, bytes32 key, bytes32 oldValue, bytes32 newValue) public canWrite(account) {
    if(key == _SALT_KEY) revert L1Keystore__InvalidKey();
    if(accounts[account].keys[key] != oldValue) revert L1Keystore__InvalidOldValue();
    accounts[account].keys[key] = newValue;
    emit KeyUpdated(account, key, oldValue, newValue);
  }
  
  function updateAccess(address account, address oldUpdateContract, address newUpdateContract) public canWrite(account) {
    accounts[account].l2KeyUpdate = newUpdateContract;
    emit AccessUpdated(account, oldUpdateContract, newUpdateContract);
  }

  function registerWallet(bytes32 _walletVersion, address _owner, uint256 _chainId, address _implementation) public {
    if(walletRegistry[_walletVersion].owner != address(0)) revert L1Keystore__WalletAlreadyRegistered();
    walletRegistry[_walletVersion].owner = _owner;
    walletRegistry[_walletVersion].implementations[_chainId] = _implementation;
    emit WalletRegistered(_walletVersion, _owner, _chainId, _implementation);
  }

  /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function getRegisteredWalletImplementation(bytes32 _walletVersion, uint256 _chainId) public view returns (address) {
    return walletRegistry[_walletVersion].implementations[_chainId];
  }
  
  function loadKey(address account, bytes32 key) public view returns (bytes32) {
    return accounts[account].keys[key];
  }
  
  function getWalletImplementation(address account) public view returns (address) {
    bytes32 walletVersion = accounts[account].keys[_WALLET_VERSION_KEY];

    address impl = walletRegistry[walletVersion].implementations[block.chainid];
    if(impl == address(0)) revert L1Keystore__ImplementationNotRegistered();
    return impl;
  }

}