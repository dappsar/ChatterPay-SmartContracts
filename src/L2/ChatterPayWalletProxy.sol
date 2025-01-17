// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ChatterPayWalletProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    function getImplementation() public view returns (address) {
        return _implementation();
    }

    // Explicit receive function
    receive() external payable {}
}