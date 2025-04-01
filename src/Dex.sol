// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IDex.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex is IDex {
    mapping(address => uint256) public tokenPrices; // Token address => price in wei per token
    mapping(address => uint256) public tokenBalances; // Token address => balance held by DEX

    // Events for tracking actions
    event Deposited(address indexed token, address indexed sender, uint256 amount);
    event Withdrawn(address indexed token, address indexed receiver, uint256 amount);
    event Bought(address indexed token, address indexed buyer, uint256 amount, uint256 ethSpent);
    event Sold(address indexed token, address indexed seller, uint256 amount, uint256 ethReceived);
    event PriceSet(address indexed token, uint256 price);

    // Deposit ERC-20 tokens into the DEX
    function depositTokens(address token, uint256 amount) external override {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenBalances[token] += amount;
        emit Deposited(token, msg.sender, amount);
    }

    // Buy tokens with ETH
    function buyTokens(address token, uint256 amount) external payable override returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        require(amount > 0, "Amount must be greater than zero");
        uint256 ethCost = (amount * price) / 1e18; // Assuming 18 decimals for simplicity
        require(msg.value >= ethCost, "Insufficient ETH sent");
        require(tokenBalances[token] >= amount, "Insufficient token balance in DEX");

        tokenBalances[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);

        // Refund excess ETH if any
        if (msg.value > ethCost) {
            payable(msg.sender).transfer(msg.value - ethCost);
        }

        emit Bought(token, msg.sender, amount, ethCost);
        return amount;
    }

    // Sell tokens for ETH
    function sellTokens(address token, uint256 amount) external override returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        require(amount > 0, "Amount must be greater than zero");
        uint256 ethAmount = (amount * price) / 1e18; // Assuming 18 decimals for simplicity
        require(address(this).balance >= ethAmount, "Insufficient ETH in DEX");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenBalances[token] += amount;
        payable(msg.sender).transfer(ethAmount);

        emit Sold(token, msg.sender, amount, ethAmount);
        return ethAmount;
    }

    // Set the price of a token in wei
    function setTokenPrice(address token, uint256 price) external override {
        require(price > 0, "Price must be greater than zero");
        tokenPrices[token] = price;
        emit PriceSet(token, price);
    }

    // Get the price of a token in wei
    function getTokenPrice(address token) external view override returns (uint256) {
        return tokenPrices[token];
    }

    // Withdraw tokens from the DEX
    function withdraw(address token, uint256 amount) external override {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenBalances[token] >= amount, "Insufficient balance");
        tokenBalances[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawn(token, msg.sender, amount);
    }

    // Allow the contract to receive ETH
    receive() external payable {}
}