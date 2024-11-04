// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ChatterPayVault__CommitmentAlreadySet();
error ChatterPayVault__NoBalanceToRedeem();
error ChatterPayVault__IncorrectPassword();
error ChatterPayVault__NoCommitmentFound();
error ChatterPayVault__UnauthorizedRedeemer();
error ChatterPayVault__InvalidCommitment();
error ChatterPayVault__CommitmentExpired();
error ChatterPayVault__NoBalanceToCancel();
error ChatterPayVault__CannotCancelActiveCommit();
error ChatterPayVault__InvalidId();
error ChatterPayVault__InvalidCommitmentHash();
error ChatterPayVault__UnauthorizedCancel();

contract ChatterPayVault {
    struct Payment {
        address wallet;
        address token;
        uint256 balance;
        bytes32 passwordHash;
        address redeemer;
        bool isReserved;
        bool isCommited;
        bool isRedeemed;
        uint256 commitTimestamp;
    }

    struct Commit {
        bytes32 commitmentHash;
        uint256 timestamp;
        address redeemer;
    }

    uint256 constant COMMIT_TIMEOUT = 1 hours;

    mapping(uint256 id => Payment) public payments;

    event PaymentReserved(
        address indexed payer,
        address indexed token,
        uint256 indexed amount
    );
    event PaymentCommitted(
        address indexed commiter,
        address indexed token,
        uint256 indexed amount
    );
    event PaymentRedeemed(
        address indexed wallet,
        address indexed token,
        address redeemer,
        uint256 amount
    );
    event PaymentCancelled(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    /** Reserve Payment **/
    function reservePayment(
        address _erc20,
        uint256 _id,
        uint256 _amount,
        bytes32 _passwordHash
    ) public {
        if (payments[_id].isReserved || payments[_id].isRedeemed)
            revert ChatterPayVault__InvalidId();
        payments[_id] = Payment({
            wallet: msg.sender,
            token: _erc20,
            balance: _amount,
            passwordHash: _passwordHash,
            redeemer: address(0),
            isReserved: true,
            isCommited: false,
            isRedeemed: false,
            commitTimestamp: 0
        });
        IERC20(_erc20).transferFrom(msg.sender, address(this), _amount);
        emit PaymentReserved(msg.sender, _erc20, _amount);
    }

    function commitForPayment(uint256 _id, bytes32 _commitmentHash) public {
        if (payments[_id].isCommited || payments[_id].isRedeemed)
            revert ChatterPayVault__InvalidId();
        if (payments[_id].passwordHash != _commitmentHash)
            revert ChatterPayVault__InvalidCommitmentHash();
        payments[_id].redeemer = msg.sender;
        payments[_id].isCommited = true;
        payments[_id].commitTimestamp = block.timestamp;
        emit PaymentCommitted(
            msg.sender,
            payments[_id].token,
            payments[_id].balance
        );
    }

    function redeemPayment(uint256 _id, string memory _password) public {
        Payment storage payment = payments[_id];
        if (payment.isRedeemed || !payment.isCommited)
            revert ChatterPayVault__InvalidId();
        if (payment.redeemer != msg.sender)
            revert ChatterPayVault__UnauthorizedRedeemer();
        if (payment.balance == 0) revert ChatterPayVault__NoBalanceToRedeem();

        if (block.timestamp > payment.commitTimestamp + COMMIT_TIMEOUT) {
            revert ChatterPayVault__CommitmentExpired();
        }

        // Verify password matches the payment's password hash
        if (keccak256(abi.encodePacked(_password)) != payment.passwordHash)
            revert ChatterPayVault__IncorrectPassword();

        // Transfer the funds
        uint256 amount = payment.balance;
        payment.balance = 0;
        payment.isRedeemed = true;
        payment.isReserved = false;
        payment.isCommited = false;
        payment.passwordHash = bytes32(0);
        IERC20(payment.token).transfer(msg.sender, amount);

        emit PaymentRedeemed(payment.wallet, payment.token, msg.sender, amount);
    }

    function cancelPayment(address _erc20, uint256 _id) public {
        Payment storage payment = payments[_id];
        if (payment.wallet != msg.sender)
            revert ChatterPayVault__UnauthorizedCancel();
        if (payment.balance == 0) revert ChatterPayVault__NoBalanceToCancel();

        // Verificar si hay un compromiso activo
        if (payment.passwordHash != bytes32(0)) {
            // Si hay un compromiso, verificar si ha expirado
            if (block.timestamp <= payment.commitTimestamp + COMMIT_TIMEOUT) {
                revert ChatterPayVault__CannotCancelActiveCommit();
            }
        }

        // Transferir los fondos de vuelta al pagador
        uint256 amount = payment.balance;
        payment.balance = 0;
        IERC20(_erc20).transfer(msg.sender, amount);
        delete payments[_id];

        emit PaymentCancelled(msg.sender, _erc20, amount);
    }
}
