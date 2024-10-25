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

contract ChatterPayVault {
    struct Payment {
        uint256 balance;
        bytes32 passwordHash;
        address redeemer; // Optional: Address of the expected redeemer
    }

    struct Commit {
        bytes32 commitmentHash;
        uint256 timestamp;
        address redeemer;
    }

    uint256 constant COMMIT_TIMEOUT = 1 hours;
    // Mapping: payer => token => id => Payment
    mapping(address payer => mapping(address token => mapping(uint256 id => Payment)))
        public reservedPayments;
    mapping(address payer => mapping(address token => mapping(uint256 id => Commit)))
        public commits;

    event PaymentReserved(
        address indexed payer,
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
        bytes32 _passwordHash,
        address _redeemer
    ) public {
        reservedPayments[msg.sender][_erc20][_id] = Payment({
            balance: _amount,
            passwordHash: _passwordHash,
            redeemer: _redeemer // Optional: Set to a specific address if known
        });
        IERC20(_erc20).transferFrom(msg.sender, address(this), _amount);
        emit PaymentReserved(msg.sender, _erc20, _amount);
    }

    function commitForPayment(
        address _wallet,
        address _token,
        uint256 _id,
        bytes32 _commitmentHash
    ) public {
        Commit storage existingCommit = commits[_wallet][_token][_id];
        if (existingCommit.commitmentHash != bytes32(0))
            revert ChatterPayVault__CommitmentAlreadySet();

        commits[_wallet][_token][_id] = Commit({
            commitmentHash: _commitmentHash,
            timestamp: block.timestamp,
            redeemer: msg.sender
        });
    }

    function redeemPayment(
        address _wallet,
        address _erc20,
        uint256 _id,
        string memory _password,
        bytes32 _nonce
    ) public {
        Payment storage payment = reservedPayments[_wallet][_erc20][_id];
        if (payment.balance == 0) revert ChatterPayVault__NoBalanceToRedeem();

        Commit storage commitEntry = commits[_wallet][_erc20][_id];
        if (commitEntry.commitmentHash == bytes32(0))
            revert ChatterPayVault__NoCommitmentFound();

        // In redeemPayment function
        if (block.timestamp > commitEntry.timestamp + COMMIT_TIMEOUT) {
            // Commitment expired
            delete commits[_wallet][_erc20][_id];
            revert ChatterPayVault__CommitmentExpired();
        }

        // Verify that the sender is the same as the committer
        if (commitEntry.redeemer != msg.sender)
            revert ChatterPayVault__UnauthorizedRedeemer();

        // Verify the commitment
        bytes32 calculatedCommitment = keccak256(
            abi.encodePacked(_password, _nonce)
        );
        if (calculatedCommitment != commitEntry.commitmentHash)
            revert ChatterPayVault__InvalidCommitment();

        // Verify password matches the payment's password hash
        if (keccak256(abi.encodePacked(_password)) != payment.passwordHash)
            revert ChatterPayVault__IncorrectPassword();

        // Verify redeemer address (optional)
        if (payment.redeemer != address(0) && payment.redeemer != msg.sender)
            revert ChatterPayVault__UnauthorizedRedeemer();

        // Clear the commitment to prevent replay attacks
        delete commits[_wallet][_erc20][_id];

        // Transfer the funds
        uint256 amount = payment.balance;
        payment.balance = 0; // Prevent re-entrancy
        IERC20(_erc20).transfer(msg.sender, amount);

        emit PaymentRedeemed(_wallet, _erc20, msg.sender, amount);
    }

    function cancelPayment(address _erc20, uint256 _id) public {
        Payment storage payment = reservedPayments[msg.sender][_erc20][_id];
        if (payment.balance == 0) revert ChatterPayVault__NoBalanceToCancel();

        Commit storage commitEntry = commits[msg.sender][_erc20][_id];

        // Verificar si hay un compromiso activo
        if (commitEntry.commitmentHash != bytes32(0)) {
            // Si hay un compromiso, verificar si ha expirado
            if (block.timestamp <= commitEntry.timestamp + COMMIT_TIMEOUT) {
                revert ChatterPayVault__CannotCancelActiveCommit();
            } else {
                // Si el compromiso ha expirado, podemos eliminarlo
                delete commits[msg.sender][_erc20][_id];
            }
        }

        // Transferir los fondos de vuelta al pagador
        uint256 amount = payment.balance;
        payment.balance = 0;
        IERC20(_erc20).transfer(msg.sender, amount);

        emit PaymentCancelled(msg.sender, _erc20, amount);
    }
}
