// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "lib/entry-point-v6/interfaces/IPaymaster.sol";

contract ChatterPayPaymaster is IPaymaster {
    address public owner;
    address public entryPoint;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("ChatterPayPaymaster: only owner can call this function");
        }
        _;
    }

    constructor(address _entryPoint) {
        owner = msg.sender;
        entryPoint = _entryPoint;
    }

    receive() external payable {}

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        context = new bytes(0);
        validationData = 0;
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
