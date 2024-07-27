// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error UserAlreadyExists();

contract Keystore is Ownable {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address userAccount => bytes32 keyHash) private userKeyHashes;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event KeyStored(address indexed user, bytes32 indexed keyHash);
    event KeyUpdated(address indexed user, bytes32 indexed keyHash);
    event KeyRemoved(address indexed user);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier userExists(address _user) {
        if (userKeyHashes[_user] != bytes32(0)) revert UserAlreadyExists();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function storeKey(
        address _user,
        bytes32 _keyHash
    ) public userExists(_user) onlyOwner {
        userKeyHashes[_user] = _keyHash;
        emit KeyStored(_user, _keyHash);
    }

    function updateKey(address _user, bytes32 _newKeyHash) public onlyOwner {
        userKeyHashes[_user] = _newKeyHash;
        emit KeyUpdated(_user, _newKeyHash);
    }

    function removeKey(address _user) public userExists(_user) onlyOwner {
        delete userKeyHashes[_user];
        emit KeyRemoved(_user);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function retrieveKey(address _user) public view returns (bytes32) {
        return userKeyHashes[_user];
    }
}
