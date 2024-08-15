// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 10**18; // 1 million tokens with 18 decimals

    constructor(address initialAccount) ERC20("Tether USD", "USDT") Ownable(initialAccount) {
        _mint(initialAccount, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}