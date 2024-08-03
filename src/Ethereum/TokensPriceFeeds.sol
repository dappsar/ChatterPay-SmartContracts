// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/api3-contracts/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

contract TokensPriceFeeds is Ownable{
    error TokensPriceFeeds__ValueNotPositive();
    error TokenPriceFeeds___InvalidAddress();
    
    constructor()Ownable(msg.sender){}
   
    function readDataFeed(address _proxy) public view returns (uint256 price, uint256 timestamp) {
        if (_proxy == address(0)) revert TokenPriceFeeds___InvalidAddress();
        (int224 value, uint256 ts) = IProxy(_proxy).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        price = uint224(value);
        timestamp = ts;
    }
}
