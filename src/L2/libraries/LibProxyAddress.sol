// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.24;

// library LibProxyAddress {
//   function computeProxyAddress(address _owner) public view returns (address) {
//     bytes memory bytecode = getProxyBytecode(_owner);
//     bytes32 hash = keccak256(
//       abi.encodePacked(
//         bytes1(0xff),
//         address(this),
//         keccak256(abi.encodePacked(_owner)),
//         keccak256(bytecode)
//       )
//     );
//     return address(uint160(uint256(hash)));
//   }

//   function getProxyBytecode(
//     address _owner
//   ) internal view returns (bytes memory) {
//       bytes memory initializationCode = abi.encodeWithSelector(
//         ChatterPay.initialize.selector,
//         entryPoint,
//         _owner,
//         l1Storage
//       );
//       return
//         abi.encodePacked(
//           type(BeaconProxy).creationCode,
//           abi.encode(beacon, initializationCode)
//         );
//       }
// }
