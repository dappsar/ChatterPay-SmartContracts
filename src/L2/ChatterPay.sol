// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IL2Keystore} from "./L2Keystore.sol";

import {console} from "forge-std/console.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IL1Blocks {
    function latestBlockNumber() external view returns (uint256);
}

contract ChatterPay is IAccount, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ChatterPay__NotFromEntryPoint();
    error ChatterPay__NotFromEntryPointOrOwner();
    error ChatterPay__ExecuteCallFailed(bytes);
    error ChatterPay__L1SLoadFailed();
    error ChatterPay__UnsopportedTokenDecimals();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IEntryPoint private i_entryPoint;
    IL2Keystore private i_l2Keystore;
    address private l1StorageAddr;
    uint256 public constant FEE_IN_CENTS = 50; // 50 cents
    address public paymaster;
    address constant BACKEND = 0xe54b48F8caF88a08849dCdDE3D3d41Cd6D7ab369;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert ChatterPay__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner() && msg.sender != BACKEND) {
            revert ChatterPay__NotFromEntryPointOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address entryPoint,
        address newOwner,
        address _l1Storage,
        address _l2Storage,
        address _paymaster
    ) public initializer {
        i_entryPoint = IEntryPoint(entryPoint);
        __Ownable_init(newOwner);
        l1StorageAddr = _l1Storage;
        paymaster = _paymaster;
        i_l2Keystore = IL2Keystore(_l2Storage);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    // Generic execute function
    function execute(
        address dest,
        uint256 value,
        bytes calldata functionData
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(
            functionData
        );
        if (!success) {
            revert ChatterPay__ExecuteCallFailed(result);
        }
    }
    
    function executeTokenTransfer(address dest, uint256 fee, bytes calldata functionData) external requireFromEntryPointOrOwner {
        if(fee != calculateFee(dest, FEE_IN_CENTS)) revert ChatterPay__ExecuteCallFailed("Incorrect fee");
        (bool feeTxSuccess, bytes memory feeTxResult) = dest.call(abi.encodeWithSignature("transfer(address,uint256)", paymaster, fee));
        if(!feeTxSuccess) {
            revert ChatterPay__ExecuteCallFailed(feeTxResult);
        }
        (bool executeSuccess, bytes memory executeResult) = dest.call(
            functionData
        );
        if (!executeSuccess) {
            revert ChatterPay__ExecuteCallFailed(executeResult);
        }
    }

    function executeTokenSwap() external requireFromEntryPointOrOwner {}
    
    // A signature is valid, if it's the ChatterPay owner
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce()
        _payPrefund(missingAccountFunds);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // EIP-191 version of the signed hash
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        
        if(block.chainid == 2227728){ // If in Scroll Devnet
            // Validate signature by using L1SLOAD & Keystore in L2/L2
            address userWalletOwner = i_l2Keystore.l1SloadGetWalletOwner(address(this));
            if (signer != userWalletOwner) {
                return SIG_VALIDATION_FAILED;
            }
        } else {
            // Validate signature by using the owner of the contract
            if (signer != owner()) {
                return SIG_VALIDATION_FAILED;
            }
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }

    // Only for Stable Coins for now
    function calculateFee(address _token, uint256 _cents) internal view returns (uint256) {
        uint256 decimals = getTokenDecimals(_token);
        uint256 fee;
        if(decimals == 6) {
            fee = _cents * 1e4;
        } else if(decimals == 18) {
            fee = _cents * 1e16;
        } else {
            revert ChatterPay__UnsopportedTokenDecimals();
        }
        return fee;
    }

    function getTokenDecimals(address token) internal view returns (uint8) {
        return IERC20(token).decimals();
    }
}
