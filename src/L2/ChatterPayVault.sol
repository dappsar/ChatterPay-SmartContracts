// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ChatterPayVault__CommitmentAlreadySet();
error ChatterPayVault__NoBalanceToRedeem();
error ChatterPayVault__InvalidCommitment();
error ChatterPayVault__IncorrectPassword();

contract ChatterPayVault {
    struct Payment {
        uint256 balance;
        bytes32 passwordHash;
        address redeemer; // Optional: Address of the expected redeemer
    }

    // Mapping: payer => token => id => Payment
    mapping(address => mapping(address => mapping(uint256 => Payment)))
        public reservedPayments;

    // Mapping: redeemer => commitment
    mapping(address => bytes32) public commitments;

    event PaymentReserved(address indexed payer, address indexed token, uint256 indexed amount);
    event CommitmentSet(address indexed commiter, bytes32 indexed commitment);
    event PaymentRedeemed(address indexed wallet, address indexed token, address redeemer, uint256 amount);
    
    /** Reserve Payment **/
    function reservePayment(
        address _erc20,
        uint256 _id,
        uint256 _amount,
        bytes32 _passwordHash
    ) public {
        reservedPayments[msg.sender][_erc20][_id] = Payment({
            balance: _amount,
            passwordHash: _passwordHash,
            redeemer: address(0) // Optional: Set to a specific address if known
        });
        IERC20(_erc20).transferFrom(msg.sender, address(this), _amount);
        emit PaymentReserved(msg.sender, _erc20, _amount);
    }

    /** Commit Phase **/

    function commit(bytes32 _commitment) public {
        if (commitments[msg.sender] != bytes32(0))
            revert ChatterPayVault__CommitmentAlreadySet();
        commitments[msg.sender] = _commitment;
        emit CommitmentSet(msg.sender, _commitment);
    }

    /** Reveal Phase **/
    // Pending: designated Redeemer -> store the redeemer’s address during the commit phase and restrict the redeemPayment function to only allow that address to redeem.

    function redeemPayment(
        address _wallet,
        address _erc20,
        uint256 _id,
        string memory _password,
        bytes32 _nonce
    ) public {
        Payment storage payment = reservedPayments[_wallet][_erc20][_id];
        if (payment.balance == 0) revert ChatterPayVault__NoBalanceToRedeem();

        // Verify commitment
        bytes32 calculatedCommitment = keccak256(
            abi.encodePacked(_password, _nonce)
        );
        if (commitments[msg.sender] != calculatedCommitment)
            revert ChatterPayVault__InvalidCommitment();

        // Verify password
        if (keccak256(abi.encodePacked(_password)) != payment.passwordHash)
            revert ChatterPayVault__IncorrectPassword();

        // Optional: Verify redeemer address
        // require(payment.redeemer == address(0) || payment.redeemer == msg.sender, "Unauthorized redeemer");

        // Clear commitment and payment balance
        commitments[msg.sender] = bytes32(0);
        uint256 amount = payment.balance;
        payment.balance = 0;

        IERC20(_erc20).transfer(msg.sender, amount);

        emit PaymentRedeemed(_wallet, _erc20, msg.sender, amount);
    }
}
