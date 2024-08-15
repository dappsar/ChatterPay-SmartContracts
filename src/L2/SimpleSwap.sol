// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public wethToken;
    IERC20 public usdtToken;
    uint256 public wethReserve;
    uint256 public usdtReserve;

    event Swap(address indexed user, uint256 wethAmount, uint256 usdtAmount);
    event LiquidityAdded(address indexed user, uint256 wethAmount, uint256 usdtAmount);

    constructor(address _wethToken, address _usdtToken) {
        require(_wethToken != address(0) && _usdtToken != address(0), "Invalid token addresses");
        wethToken = IERC20(_wethToken);
        usdtToken = IERC20(_usdtToken);
    }

    function addLiquidity(uint256 wethAmount, uint256 usdtAmount) external {
        require(wethAmount > 0 && usdtAmount > 0, "Amounts must be greater than 0");

        uint256 wethBalance = wethToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));

        wethToken.safeTransferFrom(msg.sender, address(this), wethAmount);
        usdtToken.safeTransferFrom(msg.sender, address(this), usdtAmount);

        uint256 wethTransferred = wethToken.balanceOf(address(this)) - wethBalance;
        uint256 usdtTransferred = usdtToken.balanceOf(address(this)) - usdtBalance;

        wethReserve += wethTransferred;
        usdtReserve += usdtTransferred;

        emit LiquidityAdded(msg.sender, wethTransferred, usdtTransferred);
    }

    function swapWETHforUSDT(uint256 wethAmount) external nonReentrant {
        require(wethAmount > 0, "Amount must be greater than 0");
        require(wethReserve > 0 && usdtReserve > 0, "Insufficient liquidity");
        
        uint256 usdtAmount = (usdtReserve * wethAmount) / wethReserve;
        require(usdtAmount <= usdtReserve, "Insufficient USDT in the pool");

        wethToken.safeTransferFrom(msg.sender, address(this), wethAmount);
        usdtToken.safeTransfer(msg.sender, usdtAmount);

        wethReserve += wethAmount;
        usdtReserve -= usdtAmount;

        emit Swap(msg.sender, wethAmount, usdtAmount);
    }

    function swapUSDTforWETH(uint256 usdtAmount) external nonReentrant {
        require(usdtAmount > 0, "Amount must be greater than 0");
        require(wethReserve > 0 && usdtReserve > 0, "Insufficient liquidity");

        uint256 wethAmount = (wethReserve * usdtAmount) / usdtReserve;
        require(wethAmount <= wethReserve, "Insufficient WETH in the pool");

        usdtToken.safeTransferFrom(msg.sender, address(this), usdtAmount);
        wethToken.safeTransfer(msg.sender, wethAmount);

        usdtReserve += usdtAmount;
        wethReserve -= wethAmount;

        emit Swap(msg.sender, wethAmount, usdtAmount);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (wethReserve, usdtReserve);
    }
}