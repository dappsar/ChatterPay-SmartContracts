// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "lib/entry-point-v6/interfaces/IPaymaster.sol";

contract ChatterPayPaymaster is IPaymaster {
    address public owner;

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert("ChatterPayPaymaster: only owner can call this function");
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function validatePaymasterUserOp(
        UserOperation calldata,
        bytes32,
        uint256
    )
        external
        pure
        override
        returns (bytes memory context, uint256 validationData)
    {
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
        if(!success) {
            revert("ChatterPayPaymaster: execution failed");
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
