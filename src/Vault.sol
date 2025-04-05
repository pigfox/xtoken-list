// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}

contract Vault is ReentrancyGuard {
    address public owner;
    uint256 public constant FEE_BASIS_POINTS = 5; // 0.05% (5 basis points)
    uint256 public constant FEE_DENOMINATOR = 10000; // 100% = 10000 basis points
    mapping(address => uint256) public tokenBalances;

    event FlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 fee);
    event TransactionExecuted(bytes32 indexed txId, string action);
    event Deposited(address indexed token, uint256 amount);
    event Withdrawn(address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant {
        uint256 balanceBefore = token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient vault balance");

        uint256 feeAmount = (amount * FEE_BASIS_POINTS) / FEE_DENOMINATOR;
        if (token == address(0)) {
            (bool sent, ) = receiver.call{value: amount}("");
            require(sent, "ETH transfer failed");
        } else {
            require(IERC20(token).transfer(receiver, amount), "Token transfer failed");
        }

        emit FlashLoan(receiver, token, amount, feeAmount);

        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, receiver, token, amount, data));
        emit TransactionExecuted(txId, "FlashLoan");

        bytes32 result = IFlashBorrower(receiver).onFlashLoan(msg.sender, token, amount, feeAmount, data);
        require(result == keccak256("FlashLoanBorrower.onFlashLoan"), "Invalid callback return");

        uint256 balanceAfter = token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore + feeAmount, "Loan not repaid");
    }

    function depositETH() external payable onlyOwner {
        tokenBalances[address(0)] += msg.value;
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, msg.value));
        emit Deposited(address(0), msg.value);
        emit TransactionExecuted(txId, "DepositETH");
    }

    function depositTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Deposit failed");
        tokenBalances[token] += amount;
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, amount));
        emit Deposited(token, amount);
        emit TransactionExecuted(txId, "DepositTokens");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        tokenBalances[address(0)] -= amount;
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, amount));
        emit Withdrawn(address(0), amount);
        emit TransactionExecuted(txId, "WithdrawETH");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        tokenBalances[token] -= amount;
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, amount));
        emit Withdrawn(token, amount);
        emit TransactionExecuted(txId, "WithdrawTokens");
    }

    receive() external payable {
        tokenBalances[address(0)] += msg.value;
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, msg.value));
        emit Deposited(address(0), msg.value);
        emit TransactionExecuted(txId, "ReceiveETH");
    }
}