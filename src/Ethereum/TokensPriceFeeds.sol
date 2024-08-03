// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/api3-contracts/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

contract TokensPriceFeeds is Ownable{
    error TokensPriceFeeds__ValueNotPositive();
    error TokensPriceFeeds__TimestampOlderThanOneDay();

    address public ethPriceFeed;
    address public usdcPriceFeed;
    address public wbtcPriceFeed;
    address public compPriceFeed;
    
    constructor()Ownable(msg.sender){}

    function setupEthFeed(address _ethPriceFeed) external onlyOwner {
        ethPriceFeed=_ethPriceFeed;
    }

    function setupUSDCFeed(address _usdcPriceFeed) external onlyOwner {
        usdcPriceFeed=_usdcPriceFeed;
    }

    function setupWBTCFeed(address _wbtcPriceFeed) external onlyOwner {
        wbtcPriceFeed=_wbtcPriceFeed;
    }

    function setupCOMPFeed(address _compPriceFeed) external onlyOwner {
        compPriceFeed=_compPriceFeed;
    }

    function readETHDataFeed() public view returns (uint256 price, uint256 timestamp) {
        (int224 value, uint256 ts) = IProxy(ethPriceFeed).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        if (ts + 1 days <= block.timestamp) revert TokensPriceFeeds__TimestampOlderThanOneDay();
        price = uint224(value);
        timestamp = ts;
    }

    function readUSDCDataFeed() public view returns (uint256 price, uint256 timestamp) {
        (int224 value, uint256 ts) = IProxy(usdcPriceFeed).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        if (ts + 1 days <= block.timestamp) revert TokensPriceFeeds__TimestampOlderThanOneDay();
        price = uint224(value);
        timestamp = ts;
    }

    function readWBTCDataFeed() public view returns (uint256 price, uint256 timestamp) {
        (int224 value, uint256 ts) = IProxy(wbtcPriceFeed).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        if (ts + 1 days <= block.timestamp) revert TokensPriceFeeds__TimestampOlderThanOneDay();
        price = uint224(value);
        timestamp = ts;
    }

    function readCOMPDataFeed() public view returns (uint256 price, uint256 timestamp) {
        (int224 value, uint256 ts) = IProxy(compPriceFeed).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        if (ts + 1 days <= block.timestamp) revert TokensPriceFeeds__TimestampOlderThanOneDay();
        price = uint224(value);
        timestamp = ts;
    }
}
