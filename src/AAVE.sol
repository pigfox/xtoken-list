// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32);
}

contract AAVE {
    address public owner;
    uint256 public flashLoanFee = 1e15; // 0.001 ETH flat fee for simplicity

    event FlashLoanInitiated(address indexed borrower, uint256 amount, uint256 fee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setFee(uint256 _fee) external onlyOwner {
        flashLoanFee = _fee;
    }

    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = address(this).balance;
        require(address(this).balance >= amount, "Insufficient liquidity");

        // Send ETH
        payable(receiver).transfer(amount);

        // Call back into the receiver contract
        bytes32 result = IERC3156FlashBorrower(receiver).onFlashLoan(
            address(this), token, amount, flashLoanFee, data
        );

        require(result == keccak256("ERC3156FlashBorrower.onFlashLoan"), "Invalid return value");

        // Ensure full repayment
        uint256 requiredRepayment = amount + flashLoanFee;
        require(address(this).balance >= balanceBefore + flashLoanFee, "Loan not repaid");

        emit FlashLoanInitiated(receiver, amount, flashLoanFee);
    }

    receive() external payable {}
}
