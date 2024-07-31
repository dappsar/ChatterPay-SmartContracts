// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ChatterPayWalletFactory} from "src/L2/ChatterPayWalletFactory.sol";
import {ChatterPay} from "src/L2/ChatterPay.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

error SendPackedUserOp__NoProxyDeployed();

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    // Make sure you trust this user - don't run this on Mainnet!
    address RANDOM_APPROVER = makeAddr("RANDOM_APPROVER");

    function run() public {
        // Setup
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address ANVIL_DEFAULT_USER_2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        address dest = config.usdc;
        uint256 value = 0;
        address chatterPayWalletFactoryAddress = DevOpsTools.get_most_recent_deployment("ChatterPayWalletFactory", block.chainid);
        address chatterPayProxyAddress;
        bytes memory initCode;
        if(ChatterPayWalletFactory(chatterPayWalletFactoryAddress).getProxiesCount() > 0){
            // send userOp without initCode
            chatterPayProxyAddress = ChatterPayWalletFactory(chatterPayWalletFactoryAddress).proxies(0);
            initCode = hex"";
        } else {
            // compute new address, send userOp with initCode to create account
            chatterPayProxyAddress = ChatterPayWalletFactory(chatterPayWalletFactoryAddress).computeProxyAddress(ANVIL_DEFAULT_USER_2);
            bytes memory encodedData = abi.encodeWithSignature("createProxy(address)", ANVIL_DEFAULT_USER_2);
            bytes memory encodedFactory = abi.encodePacked(chatterPayWalletFactoryAddress);
            initCode = abi.encodePacked(encodedFactory, encodedData);
        }

        // Example: approve 1e18 USDC to RANDOM_APPROVER
        bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, RANDOM_APPROVER, 1e18);
        bytes memory executeCalldata =
            abi.encodeWithSelector(ChatterPay.execute.selector, dest, value, functionData);
        
        PackedUserOperation memory userOp =
            generateSignedUserOperation(initCode, executeCalldata, helperConfig.getConfig(), chatterPayProxyAddress);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        // Send transaction
        vm.startBroadcast();
        IEntryPoint(config.entryPoint).handleOps(ops, payable(config.account));
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(
        bytes memory initCode,
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address chatterPayProxy
    ) public view returns (PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(chatterPayProxy);

        PackedUserOperation memory userOp = _generateUnsignedUserOperation(initCode, callData, chatterPayProxy, nonce);

        // 2. Get the userOp Hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY_2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY_2, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); // Note the order
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory initCode, bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: 0,
            initCode: initCode,
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
