// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

struct PackedUserOperation {
    address sender;                // The address of the sender
    uint256 nonce;                 // The nonce of the operation
    bytes initCode;                // The initialization code for the operation
    bytes callData;                // The call data for the operation
    uint256 callGasLimit;          // The gas limit for the call
    uint256 verificationGasLimit;  // The gas limit for verification
    uint256 preVerificationGas;    // The gas used before the main execution
    uint256 maxFeePerGas;          // The maximum fee per gas unit the user is willing to pay
    uint256 maxPriorityFeePerGas;  // The maximum priority fee per gas unit
    bytes paymasterAndData;        // The paymaster data, if any
    bytes signature;               // The signature of the operation
}