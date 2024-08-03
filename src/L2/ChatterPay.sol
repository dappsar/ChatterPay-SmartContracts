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
    address constant L1_BLOCKS_ADDRESS =
        0x5300000000000000000000000000000000000001; // Scroll Devnet Only!
    address constant L1_SLOAD_ADDRESS =
        0x0000000000000000000000000000000000000101; // Scroll Devnet Only!
    address private l1StorageAddr;
    uint256 public constant FEE_IN_CENTS = 50; // 50 cents
    address public paymaster;

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
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
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

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
        console.log("Signer: %s", signer);
        
        if(block.chainid == 2227728){ // If in Scroll Devnet
            // Validate signature by using L1SLOAD & Keystore in L2/L2
            address userWalletOwner = i_l2Keystore.l1SloadGetWalletOwner(address(this));
            console.log("User Wallet: %s", userWalletOwner);
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

    function latestL1BlockNumber() public view returns (uint256) {
        uint256 l1BlockNum = IL1Blocks(L1_BLOCKS_ADDRESS).latestBlockNumber();
        return l1BlockNum;
    }

    function retrieveFromL1() public view returns (uint) {
        uint256 NUMBER_SLOT; // @dev TBD Slot Number
        bytes memory input = abi.encodePacked(l1StorageAddr, NUMBER_SLOT);
        (bool success, bytes memory ret) = L1_SLOAD_ADDRESS.staticcall(input);
        if (!success) {
            revert ChatterPay__L1SLoadFailed();
        }
        return abi.decode(ret, (uint256));
    }
}
