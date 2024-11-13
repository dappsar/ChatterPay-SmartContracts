// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
//////////////////////////////////////////////////////////////*/

import {IAccount, UserOperation} from "lib/entry-point-v6/interfaces/IAccount.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/entry-point-v6/interfaces/IEntryPoint.sol";
import {ITokensPriceFeeds} from "../Ethereum/TokensPriceFeeds.sol";

/*//////////////////////////////////////////////////////////////
                                ERRORS
//////////////////////////////////////////////////////////////*/

error ChatterPay__NotFromEntryPoint();
error ChatterPay__NotFromEntryPointOrOwner();
error ChatterPay__ExecuteCallFailed(bytes);
error ChatterPay__UnsopportedTokenDecimals();
error ChatterPay__API3Failed();
error ChatterPay__UnsopportedToken();
error ChatterPay__InvalidAmountOfTokens();
error ChatterPay__InvalidTokenReceiver();
error ChatterPay__NoTokenBalance(address);
error ChatterPay__BalanceTxFailed();

/*//////////////////////////////////////////////////////////////
                               INTERFACES
//////////////////////////////////////////////////////////////*/

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

/*//////////////////////////////////////////////////////////////
                                CONTRACT
//////////////////////////////////////////////////////////////*/

contract ChatterPay is IAccount, UUPSUpgradeable, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IEntryPoint private s_entryPoint;
    address public s_paymaster;
    address public s_api3PriceFeed;
    string[1] public s_supportedStableTokens;
    string[2] public s_supportedNotStableTokens;

    uint256 public constant FEE_IN_CENTS = 50; // 50 cents

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Execution(
        address indexed wallet,
        address indexed dest,
        uint256 indexed value,
        bytes functionData
    );
    event TokenTransfer(
        address indexed wallet,
        address indexed dest,
        uint256 indexed fee,
        bytes functionData
    );
    event EntryPointSet(address indexed entryPoint);
    event WithdrawBalance(address[] indexed, address indexed to);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier requireFromEntryPoint() {
        if (msg.sender != address(s_entryPoint)) {
            revert ChatterPay__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(s_entryPoint) && msg.sender != owner()) {
            revert ChatterPay__NotFromEntryPointOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _entryPoint,
        address _owner,
        address _paymaster
    ) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        s_entryPoint = IEntryPoint(_entryPoint);
        s_paymaster = _paymaster;
        s_supportedStableTokens = ["USDT"];
        s_supportedNotStableTokens = ["WETH", "WBTC"];
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL AND PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    // Generic execute function
    function execute(
        address dest,
        uint256 value,
        bytes calldata functionData
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(
            functionData
        );
        if (!success) {
            revert ChatterPay__ExecuteCallFailed(result);
        }
        emit Execution(address(this), dest, value, functionData);
    }

    function executeTokenTransfer(
        address dest,
        uint256 fee,
        bytes calldata functionData
    ) external requireFromEntryPointOrOwner {
        if (fee != calculateFee(dest, FEE_IN_CENTS))
            revert ChatterPay__ExecuteCallFailed("Incorrect fee");

        (bool feeTxSuccess, bytes memory feeTxResult) = dest.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                s_paymaster,
                fee
            )
        );
        if (!feeTxSuccess) {
            revert ChatterPay__ExecuteCallFailed(feeTxResult);
        }

        (bool executeSuccess, bytes memory executeResult) = dest.call(
            functionData
        );
        if (!executeSuccess) {
            revert ChatterPay__ExecuteCallFailed(executeResult);
        }
        emit TokenTransfer(address(this), dest, fee, functionData);
    }

    // A signature is valid, if it's the ChatterPay owner
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce()
        _payPrefund(missingAccountFunds);
    }

    function withdrawBalance(
        address[] memory tokenAddresses,
        address to
    ) external onlyOwner returns (bool) {
        if (
            tokenAddresses.length >
            s_supportedNotStableTokens.length + s_supportedStableTokens.length
        ) {
            revert ChatterPay__InvalidAmountOfTokens();
        }
        if (to == address(0) || to.code.length > 0)
            revert ChatterPay__InvalidTokenReceiver();

        for (uint256 i; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == address(0)) {
                (bool success, ) = payable(to).call{
                    value: address(this).balance
                }("");
                if (!success) revert ChatterPay__BalanceTxFailed();
            } else {
                IERC20 token = IERC20(tokenAddresses[i]);
                uint256 balance = token.balanceOf(address(this));
                if (balance == 0)
                    revert ChatterPay__NoTokenBalance(tokenAddresses[i]);
                bool success = token.transfer(to, balance);
                if (!success) revert ChatterPay__BalanceTxFailed();
            }
        }

        emit WithdrawBalance(tokenAddresses, to);
        return true;
    }

    function setEntryPoint(address _entryPoint) external onlyOwner {
        s_entryPoint = IEntryPoint(_entryPoint);
        emit EntryPointSet(_entryPoint);
    }

    function setPriceFeedAddress(address _priceFeed) public onlyOwner {
        s_api3PriceFeed = _priceFeed;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) return 1;
        return 0;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
        }
    }

    function calculateFee(
        address _token,
        uint256 _cents
    ) internal view returns (uint256) {
        string memory symbol = getTokenSymbol(_token);
        bool isStable = isStableToken(symbol);
        uint256 decimals = getTokenDecimals(_token);
        uint256 oraclePrice;
        uint256 fee;
        if (!isStable) {
            oraclePrice = getAPI3OraclePrice(symbol);
            fee = calculateFeeNotStable(oraclePrice, _cents);
        } else {
            fee = calculateFeeStable(decimals, _cents);
        }
        return fee;
    }

    function isStableToken(string memory _symbol) internal view returns (bool) {
        string[1] memory m_supportedStableTokens = s_supportedStableTokens;
        string[2]
            memory m_supportedNotStableTokens = s_supportedNotStableTokens;
        for (uint256 i; i < m_supportedStableTokens.length; i++) {
            if (
                keccak256(abi.encodePacked(_symbol)) ==
                keccak256(abi.encodePacked(m_supportedStableTokens[i]))
            ) {
                return true;
            }
        }
        for (uint256 i; i < m_supportedNotStableTokens.length; i++) {
            if (
                keccak256(abi.encodePacked(_symbol)) ==
                keccak256(abi.encodePacked(m_supportedNotStableTokens[i]))
            ) {
                return false;
            }
        }
        revert ChatterPay__UnsopportedToken();
    }

    function calculateFeeStable(
        uint256 _decimals,
        uint256 _cents
    ) internal pure returns (uint256) {
        uint256 fee;
        if (_decimals == 6) {
            fee = _cents * 1e4;
        } else if (_decimals == 18) {
            fee = _cents * 1e16;
        } else {
            revert ChatterPay__UnsopportedTokenDecimals();
        }
        return fee;
    }

    function calculateFeeNotStable(
        uint256 oraclePrice,
        uint256 cents
    ) internal pure returns (uint256) {
        uint256 dollarsIn18Decimals = (cents * 10 ** 16);
        uint256 fee = (dollarsIn18Decimals * 10 ** 18) / oraclePrice;
        return fee;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEntryPoint() external view returns (address) {
        return address(s_entryPoint);
    }

    function getAPI3OraclePrice(
        string memory _token
    ) internal view returns (uint256) {
        if (s_api3PriceFeed == address(0)) revert ChatterPay__API3Failed();
        // Call API3 Oracle
        uint256 price;
        uint256 ts;
        address token;
        if (
            keccak256(abi.encodePacked(_token)) ==
            keccak256(abi.encodePacked("ETH"))
        ) {
            token = ITokensPriceFeeds(s_api3PriceFeed).ETH_USD_Proxy();
        } else if (
            keccak256(abi.encodePacked(_token)) ==
            keccak256(abi.encodePacked("BTC"))
        ) {
            token = ITokensPriceFeeds(s_api3PriceFeed).BTC_USD_Proxy();
        } else {
            revert ChatterPay__API3Failed();
        }
        (price, ts) = ITokensPriceFeeds(s_api3PriceFeed).readDataFeed(token);
        return price;
    }

    function getTokenDecimals(address token) internal view returns (uint8) {
        return IERC20(token).decimals();
    }

    function getTokenSymbol(
        address token
    ) internal view returns (string memory) {
        return IERC20(token).symbol();
    }
}
