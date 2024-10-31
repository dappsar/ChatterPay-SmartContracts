// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "lib/entry-point-v6/interfaces/IPaymaster.sol";

error ChatterPayPaymaster__InvalidDataLength();
error ChatterPayPaymaster__SignatureExpired();
error ChatterPayPaymaster__InvalidSignature();

contract ChatterPayPaymaster is IPaymaster {
    address public owner;
    address public entryPoint;
    address private backendSigner;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("ChatterPayPaymaster: only owner can call this function");
        }
        _;
    }

    constructor(address _entryPoint, address _backendSigner) {
        owner = msg.sender;
        entryPoint = _entryPoint;
        backendSigner = _backendSigner;
    }

    receive() external payable {}

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /* userOpHash */,
        uint256 /* maxCost */
    )
        external
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        _requireFromEntryPoint();
        bytes memory paymasterAndData = userOp.paymasterAndData;
        // Expected format:
        // paymasterAndData = paymasterAddress (20 bytes) + signature (65 bytes) + expiration (8 bytes)
        if (paymasterAndData.length != 20 + 65 + 8)
            revert ChatterPayPaymaster__InvalidDataLength();
        // Extract the signature and expiration
        uint256 offset = 20; // Skip the paymaster address

        bytes memory signature = new bytes(65);
        for (uint256 i = 0; i < 65; i++) {
            signature[i] = paymasterAndData[offset + i];
        }
        offset += 65;
        // Extract expiration timestamp (uint64)
        uint64 expiration;
        assembly {
            expiration := mload(add(paymasterAndData, add(offset, 8)))
        }
        // Check if the signature is expired
        if (block.timestamp > expiration)
            revert ChatterPayPaymaster__SignatureExpired();
        // Reconstruct the signed message
        bytes32 messageHash = keccak256(
            abi.encodePacked(userOp.sender, expiration)
        );
        // Recover the signer address
        address recoveredAddress = _recoverSigner(messageHash, signature);
        if (recoveredAddress != backendSigner)
            revert ChatterPayPaymaster__InvalidSignature();

        context = new bytes(0);
        validationData = 0;
    }

    function _recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        // Split signature into r, s, v
        if (signature.length != 65)
            revert ChatterPayPaymaster__InvalidSignature();
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // Adjust v value
        if (v < 27) {
            v += 27;
        }
        // Recover the signer address
        return ecrecover(messageHash, v, r, s);
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override {}

    function execute(
        address dest,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        (bool success, ) = dest.call{value: value}(data);
        if (!success) {
            revert("ChatterPayPaymaster: execution failed");
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _requireFromEntryPoint() internal view {
        if (msg.sender != entryPoint) {
            revert(
                "ChatterPayPaymaster: only entry point can call this function"
            );
        }
    }
}
