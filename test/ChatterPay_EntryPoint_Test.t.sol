// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployChatterPay_EntryPoint} from "../script/DeployChatterPay_EntryPoint.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPay.sol";
import {ChatterPayWalletFactory} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPayWalletFactory.sol";
import {ChatterPayBeacon} from "../src/L2/AccountAbstraction_EntryPoint/ChatterPayBeacon.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";


// Chequear Owners
// Chequear envio de transacciones
contract ChatterPay_EntryPoint_Test is Test {

  HelperConfig helperConfig;
  ChatterPay chatterPay;
  ChatterPayBeacon beacon;
  ChatterPayWalletFactory factory;
  ERC20Mock usdc;
  SendPackedUserOp sendPackedUserOp;
  address deployer;
  address RANDOM_USER = makeAddr("randomUser");
  address RANDOM_APPROVER = makeAddr("RANDOM_APPROVER");
  
  function setUp() public {
    DeployChatterPay_EntryPoint deployChatterPay = new DeployChatterPay_EntryPoint();
    (helperConfig, chatterPay, beacon, factory) = deployChatterPay.deployChatterPay();
    deployer = helperConfig.getConfig().account;
    usdc = new ERC20Mock();
    sendPackedUserOp = new SendPackedUserOp();
    chatterPay = chatterPay;
    beacon = beacon;
    factory = factory;
  }

  function createProxyForRandomUser() public returns (address) {
    address proxy = factory.createProxy(RANDOM_USER);
    assertEq(factory.getProxiesCount(), 1, "There should be 1 proxy");
    return proxy;
  }

  function testSetup() public view {
    assertEq(address(chatterPay), address(beacon.implementation()), "ChatterPay and Beacon should have the same implementation");
  }

  function testOwners() public view {
    assertEq(factory.owner(), deployer, "Owner should be the test contract");
  }

  function testDeployProxy() public {
    vm.startPrank(deployer);
    address proxy = factory.createProxy(RANDOM_USER);
    assertEq(factory.proxies(0), proxy, "Proxy should be stored in the factory");
  }

  function testApproveUSDC() public {
    vm.startPrank(deployer); // helperConfig.getConfig().account;
    address proxy = createProxyForRandomUser();
    
    // Assign random ETH to proxy to pay for gas
    vm.deal(proxy, 1 ether);
    
    // Setup
    address dest = helperConfig.getConfig().usdc;
    uint256 value = 0;

    // Example: approve 1e18 USDC to RANDOM_APPROVER
    bytes memory functionData = abi.encodeWithSelector(usdc.approve.selector, RANDOM_APPROVER, 1e18);
    bytes memory executeCalldata =
        abi.encodeWithSelector(ChatterPay.execute.selector, dest, value, functionData);
    PackedUserOperation memory userOp =
        sendPackedUserOp.generateSignedUserOperation(executeCalldata, helperConfig.getConfig(), proxy);
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = userOp;

    IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(proxy));
    
    vm.stopPrank();
  }
}