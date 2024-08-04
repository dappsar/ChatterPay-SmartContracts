// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/api3-contracts/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

contract TokensPriceFeeds is Ownable {
    
    error TokensPriceFeeds__ValueNotPositive();
    error TokensPriceFeeds__TimestampTooOld();
    error TokenPriceFeeds___InvalidAddress();

    // 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address public ETH_USD_Proxy;
    // 0xECe365B379E1dD183B20fc5f022230C044d51404    
    address public BTC_USD_Proxy;

    event ProxyAddressSet(address proxyAddress);
    
    constructor(address _ETH_USD_Proxy, address _BTC_USD_Proxy) Ownable(msg.sender) {
        ETH_USD_Proxy = _ETH_USD_Proxy;
        BTC_USD_Proxy = _BTC_USD_Proxy;
    }

    function setETHProxyAddress(address _proxyAddress) public onlyOwner {
        ETH_USD_Proxy = _proxyAddress;
        emit ProxyAddressSet(_proxyAddress);
    }

    function setBTCProxyAddress(address _proxyAddress) public onlyOwner {
        BTC_USD_Proxy = _proxyAddress;
        emit ProxyAddressSet(_proxyAddress);
    }
   
    function readDataFeed(address _proxy) public view returns (uint256 price, uint256 timestamp) {
        if (_proxy == address(0)) revert TokenPriceFeeds___InvalidAddress();
        (int224 value, uint256 ts) = IProxy(_proxy).read();
        if (value <= 0) revert TokensPriceFeeds__ValueNotPositive();
        if(ts + 1 days < block.timestamp) revert TokensPriceFeeds__TimestampTooOld();
        price = uint224(value);
        timestamp = ts;
    }
}
