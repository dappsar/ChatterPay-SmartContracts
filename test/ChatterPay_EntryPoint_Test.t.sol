// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployChatterPay_EntryPoint} from "../script/DeployChatterPay_EntryPoint.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ChatterPay} from "../src/L2/ChatterPay.sol";
import {ChatterPayWalletFactory} from "../src/L2/ChatterPayWalletFactory.sol";
import {ChatterPayBeacon} from "../src/L2/ChatterPayBeacon.sol";
import {L1Keystore} from "../src/Ethereum/L1Keystore.sol";
import {L2Keystore} from "../src/L2/L2Keystore.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";


// Chequear Owners
// Chequear envio de transacciones
contract ChatterPay_EntryPoint_Test is Test {

  HelperConfig helperConfig;
  ChatterPay chatterPay;
  ChatterPayBeacon beacon;
  ChatterPayWalletFactory factory;
  L1Keystore l1Keystore;
  L2Keystore l2Keystore;
  ERC20Mock usdc;
  SendPackedUserOp sendPackedUserOp;
  address deployer;
  address RANDOM_USER = makeAddr("randomUser");
  address RANDOM_APPROVER = makeAddr("RANDOM_APPROVER");
  address ANVIL_DEFAULT_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
  
  function setUp() public {
    DeployChatterPay_EntryPoint deployChatterPay = new DeployChatterPay_EntryPoint();
    (helperConfig, chatterPay, beacon, factory, l1Keystore, l2Keystore) = deployChatterPay.deployChatterPayL2();
    usdc = new ERC20Mock();
    sendPackedUserOp = new SendPackedUserOp();
    chatterPay = chatterPay;
    beacon = beacon;
    factory = factory;
    deployer = helperConfig.getConfig().account;
  }

  function createProxyForUser(address user) public returns (address) {
    address proxy = factory.createProxy(user);
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

  function testCreateWalletWithUserOperationInitCode() public {}

  function testApproveUsdcWithoutInitCode() public {
    vm.startPrank(deployer);
    
    address proxyAddress = createProxyForUser(ANVIL_DEFAULT_USER);
    
    // Assign ETH to proxy for gas
    vm.deal(proxyAddress, 1 ether);
    
    // Set up destination, value and null initCode
    address dest = helperConfig.getConfig().usdc;
    uint256 value = 0;
    bytes memory initCode = hex"";

    // Encode approve function call
    bytes memory functionData = abi.encodeWithSelector(usdc.approve.selector, RANDOM_APPROVER, 1e18);
    bytes memory executeCalldata =
        abi.encodeWithSelector(ChatterPay.execute.selector, dest, value, functionData);
    
    // Generate signed user operation
    PackedUserOperation memory userOp =
        sendPackedUserOp.generateSignedUserOperation(initCode, executeCalldata, helperConfig.getConfig(), proxyAddress);
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = userOp;

    // Execute handleOps
    IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(proxyAddress));
    
    // Check allowance
    uint256 allowance = ERC20Mock(dest).allowance(proxyAddress, RANDOM_APPROVER);
    console.log("Allowance after operation:", allowance);
    
    // Assert expected allowance
    assertEq(allowance, 1e18, "Proxy should have approved 1e18 USDC to RANDOM_APPROVER");
    
    vm.stopPrank();
  }

  function testApproveUsdcWithInitCode() public {
    vm.startPrank(deployer);
    
    // Compute new address, send userOp with initCode to create account
    address proxyAddress = factory.computeProxyAddress(ANVIL_DEFAULT_USER);
    console.log("Computed Proxy Address:", proxyAddress);
    
    // Generate initCode
    bytes memory encodedData = abi.encodeWithSelector(ChatterPayWalletFactory.createProxy.selector, ANVIL_DEFAULT_USER);
    bytes memory encodedFactory = abi.encodePacked(address(factory));
    bytes memory initCode = abi.encodePacked(encodedFactory, encodedData);

    // Assign ETH to proxy for gas
    vm.deal(proxyAddress, 1 ether);
    console.log("Assigned ETH to Proxy");
    
    // Set up destination and value
    address dest = helperConfig.getConfig().usdc;
    uint256 value = 0;

    // Encode approve function call
    bytes memory functionData = abi.encodeWithSelector(usdc.approve.selector, RANDOM_APPROVER, 1e18);
    bytes memory executeCalldata = abi.encodeWithSelector(ChatterPay.execute.selector, dest, value, functionData);

    // Generate signed user operation
    PackedUserOperation memory userOp =
        sendPackedUserOp.generateSignedUserOperation(initCode, executeCalldata, helperConfig.getConfig(), proxyAddress);
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = userOp;
    
    // Execute handleOps
    IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(proxyAddress));

    // Check allowance
    uint256 allowance = ERC20Mock(dest).allowance(proxyAddress, RANDOM_APPROVER);
    console.log("Allowance after operation:", allowance);
    
    // Assert expected allowance
    assertEq(allowance, 1e18, "Proxy should have approved 1e18 USDC to RANDOM_APPROVER");
    
    vm.stopPrank();
  }

   function testTransferUSDCWithFee() public {
    vm.startPrank(deployer);
    
    address proxyAddress = createProxyForUser(ANVIL_DEFAULT_USER);
    
    // Assign ETH to proxy for gas
    vm.deal(proxyAddress, 1 ether);
    
    // Set up destination, value and null initCode
    address dest = helperConfig.getConfig().usdc;
    uint256 fee = 500000000000000000; // ERC20 contract with 18 decimals (50 cents)
    bytes memory initCode = hex"";

    // Mint USDC to Proxy
    ERC20Mock(dest).mint(proxyAddress, 1e18);

    // Encode approve function call
    bytes memory functionData = abi.encodeWithSelector(usdc.transfer.selector, RANDOM_APPROVER, 1e6);
    bytes memory executeCalldata =
        abi.encodeWithSelector(ChatterPay.executeTokenTransfer.selector, dest, fee, functionData);
    
    // Generate signed user operation
    PackedUserOperation memory userOp =
        sendPackedUserOp.generateSignedUserOperation(initCode, executeCalldata, helperConfig.getConfig(), proxyAddress);
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = userOp;

    // Execute handleOps
    IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(proxyAddress));

    // Check balance
    uint256 balance = ERC20Mock(dest).balanceOf(RANDOM_APPROVER);
    console.log("Balance after operation:", balance);
    
    // Assert expected allowance
    assertEq(balance, 1e6, " RANDOM_APPROVER should have a balance of 1e17");

    vm.stopPrank();
  }

  function testStorageSlot() public {
    
    // Register Wallet
    bytes32 walletVersion = bytes32(uint256(1));
    address owner = ANVIL_DEFAULT_USER;
    uint256 chainId = block.chainid;
    address implementation = address(chatterPay);
    l1Keystore.registerWallet(walletVersion, owner, chainId, implementation);
    assertEq(l1Keystore.getRegisteredWalletImplementation(walletVersion, chainId), implementation, "Wallet implementation should be registered");

    // Register Account
    address wallet = l1Keystore.registerAccount(owner, keccak256(abi.encodePacked(owner)), walletVersion, new bytes32[](0), new bytes32[](0), "", address(0), "123");
    
    bytes32 slot = bytes32(l2Keystore._computeOwnerSlot(wallet));
    bytes32 l1Slot = vm.load(address(l1Keystore), slot);
    address l1Owner = address(uint160(uint256(l1Slot)));

    assertEq(l1Owner, ANVIL_DEFAULT_USER, "Owner should be the wallet");
  }
}