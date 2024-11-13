// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
//////////////////////////////////////////////////////////////*/

import {IAccount, UserOperation} from "lib/entry-point-v6/interfaces/IAccount.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/entry-point-v6/interfaces/IEntryPoint.sol";

/*//////////////////////////////////////////////////////////////
                                ERRORS
//////////////////////////////////////////////////////////////*/

error ChatterPay__NotFromEntryPoint();
error ChatterPay__NotFromEntryPointOrOwner();
error ChatterPay__ExecuteCallFailed(bytes);
error ChatterPay__UnsopportedToken();
error ChatterPay__InvalidAmountOfTokens();
error ChatterPay__InvalidTokenReceiver();
error ChatterPay__NoTokenBalance(address);
error ChatterPay__BalanceTxFailed();
error ChatterPay__PrefundFailed();

/*//////////////////////////////////////////////////////////////
                               INTERFACES
//////////////////////////////////////////////////////////////*/

interface IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

/*//////////////////////////////////////////////////////////////
                                CONTRACT
//////////////////////////////////////////////////////////////*/

contract ChatterPay is IAccount, UUPSUpgradeable, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IEntryPoint private s_entryPoint;
    string[1] public s_supportedStableTokens;
    string[2] public s_supportedNotStableTokens;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Execution(
        address indexed wallet,
        address indexed dest,
        uint256 indexed value,
        bytes functionData
    );
    event EntryPointSet(address indexed entryPoint);
    event WithdrawBalance(address[] tokenAddresses, address indexed to);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier requireFromEntryPoint() {
        if (msg.sender != address(s_entryPoint)) {
            revert ChatterPay__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(s_entryPoint) && msg.sender != owner()) {
            revert ChatterPay__NotFromEntryPointOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _entryPoint,
        address _owner
    ) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        s_entryPoint = IEntryPoint(_entryPoint);
        s_supportedStableTokens = ["USDT"];
        s_supportedNotStableTokens = ["WETH", "WBTC"];
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL AND PUBLIC FUNCTIONS
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
        emit Execution(address(this), dest, value, functionData);
    }

    // A signature is valid, if it's the ChatterPay owner
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce()
        _payPrefund(missingAccountFunds);
    }

    function withdrawBalance(
        address[] memory tokenAddresses,
        address to
    ) external onlyOwner returns (bool) {
        if (
            tokenAddresses.length >
            s_supportedNotStableTokens.length + s_supportedStableTokens.length
        ) {
            revert ChatterPay__InvalidAmountOfTokens();
        }
        if (to == address(0) || to.code.length > 0)
            revert ChatterPay__InvalidTokenReceiver();

        for (uint256 i; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == address(0)) {
                (bool success, ) = payable(to).call{
                    value: address(this).balance
                }("");
                if (!success) revert ChatterPay__BalanceTxFailed();
            } else {
                IERC20 token = IERC20(tokenAddresses[i]);
                uint256 balance = token.balanceOf(address(this));
                if (balance == 0)
                    revert ChatterPay__NoTokenBalance(tokenAddresses[i]);
                bool success = token.transfer(to, balance);
                if (!success) revert ChatterPay__BalanceTxFailed();
            }
        }

        emit WithdrawBalance(tokenAddresses, to);
        return true;
    }

    function setEntryPoint(address _entryPoint) external onlyOwner {
        s_entryPoint = IEntryPoint(_entryPoint);
        emit EntryPointSet(_entryPoint);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) return 1;
        return 0;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            if (!success) revert ChatterPay__PrefundFailed();
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEntryPoint() external view returns (address) {
        return address(s_entryPoint);
    }
}
