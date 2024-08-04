// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/api3-contracts/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

interface ITokensPriceFeeds {
    function readDataFeed(address _proxy) external view returns (uint256 price, uint256 timestamp);
    function ETH_USD_Proxy() external view returns (address);
    function BTC_USD_Proxy() external view returns (address);
}

contract TokensPriceFeeds is Ownable {
    
    error TokensPriceFeeds__ValueNotPositive();
    error TokensPriceFeeds__TimestampTooOld();
    error TokenPriceFeeds___InvalidAddress();

    // 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1 for Scroll Sepolia
    address public ETH_USD_Proxy;
    // 0x81A64473D102b38eDcf35A7675654768D11d7e24 for Scroll Sepolia
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
