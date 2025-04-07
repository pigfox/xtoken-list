// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IDex.sol";

contract Arbitrage is IERC3156FlashBorrower, ReentrancyGuard {
    address public flashLoanProviderAddress;
    address public profitAddress;
    address public owner;

    // Events for debugging and monitoring
    event FlashLoanReceived(address indexed sender, address indexed initiator, uint256 amount, uint256 fee);
    event ArbitrageStep(address indexed dex, address indexed token, uint256 amountIn, uint256 amountOut);
    event LoanRepaid(address indexed lender, uint256 amount);
    event ProfitSent(address indexed recipient, uint256 amount);
    event UpdatedOwner(address indexed newOwner);
    event UpdatedProfitAddress(address indexed newProfitAddress);

    constructor(address _flashLoanProviderAddress) {
        require(_flashLoanProviderAddress != address(0), "Invalid flash loan provider");
        flashLoanProviderAddress = _flashLoanProviderAddress;
        profitAddress = msg.sender;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setOwner(address _owner) onlyOwner external {
        require(owner == msg.sender, "Owner already set");
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setProfitAddress(address _profitAddress) onlyOwner external {
        require(_profitAddress != address(0), "Invalid profit address");
        profitAddress = _profitAddress;
        emit UpdatedProfitAddress(_profitAddress);
    }

    function getProfitAddress() external view returns (address) {
        return profitAddress;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override nonReentrant onlyOwner returns (bytes32) {
        // Ensure the caller is the Vault
        //require(msg.sender == flashLoanProviderAddress, "Invalid initiator");
        require(token == address(0), "Only ETH flash loans supported");

        // Emit event for flash loan receipt
        emit FlashLoanReceived(msg.sender, initiator, amount, fee);

        // Decode arbitrage data
        (address tokenToTrade, address dex2, address dex1, uint256 tradeAmount) = abi.decode(data, (address, address, address, uint256));

        // Perform arbitrage: Buy on DEX2 (cheaper), sell on DEX1 (expensive)
        IERC20(tokenToTrade).approve(dex2, tradeAmount);
        uint256 tokensBought = IDex(dex2).buyTokens{value: amount}(tokenToTrade, tradeAmount);
        emit ArbitrageStep(dex2, tokenToTrade, amount, tokensBought);

        IERC20(tokenToTrade).approve(dex1, tokensBought);
        uint256 ethReceived = IDex(dex1).sellTokens(tokenToTrade, tokensBought);
        emit ArbitrageStep(dex1, tokenToTrade, tokensBought, ethReceived);

        // Repay flash loan
        uint256 totalRepayment = amount + fee;
        require(address(this).balance >= totalRepayment, "Insufficient ETH to repay");
        payable(flashLoanProviderAddress).transfer(totalRepayment);
        emit LoanRepaid(flashLoanProviderAddress, totalRepayment);

        // Send profit to profitAddress
        uint256 profit = address(this).balance;
        if (profit > 0) {
            payable(profitAddress).transfer(profit);
            emit ProfitSent(profitAddress, profit);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Allow contract to receive ETH
    receive() external payable {}
}