// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./BeaconAccessor.sol";

contract CustomBeaconProxy is BeaconProxy {
    /**
     * @dev Initializes the proxy with the BeaconAccessor address.
     * @param beaconAccessor The address of the BeaconAccessor contract.
     * @param data Optional initialization data.
     */
    constructor(
        address beaconAccessor,
        bytes memory data
    ) BeaconProxy(beaconAccessor, data) {}

    /**
     * @dev Overrides the _implementation function to fetch the implementation from BeaconAccessor.
     */
    function _implementation() internal view override returns (address impl) {
        BeaconAccessor accessor = BeaconAccessor(payable(_getBeacon()));
        impl = accessor.implementation();
    }
}
