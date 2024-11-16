// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SingleTokenDex {
    address public owner;

    // Reserve mapping for each token
    mapping(address => uint256) public reserves;
    // Mapping to store token prices in relation to a reserve
    mapping(address => uint256) public tokenPrices;

    // Event to track token deposits and withdrawals
    event TokenDeposited(address token, uint256 amount, address sender);
    event TokenWithdrawn(address token, uint256 amount, address sender);
    event TokenSwapped(address fromToken, address toToken, uint256 amountIn, uint256 amountOut);

    constructor() {
        owner = msg.sender;
    }

    // Modifier to ensure only the owner can execute certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Deposit tokens into the DEX contract
    function depositTokens(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        reserves[token] += amount;
        emit TokenDeposited(token, amount, msg.sender);
    }

    // Withdraw tokens from the DEX contract
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(amount > 0 && reserves[token] >= amount, "Insufficient balance");
        reserves[token] -= amount;

        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit TokenWithdrawn(token, amount, msg.sender);
    }

    // Set token price relative to reserve
    function setTokenPrice(address token, uint256 price) external onlyOwner {
        require(price > 0, "Price must be greater than 0");
        tokenPrices[token] = price;
    }

    // Fetch the price of a token
    function getPrice(address token) external view returns (uint256) {
        return tokenPrices[token];
    }

    // Swap one token for another (XToken -> TokenB or vice versa)
    function swapTokens(address fromToken, address toToken, uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");
        uint256 fromTokenPrice = tokenPrices[fromToken];
        uint256 toTokenPrice = tokenPrices[toToken];

        require(fromTokenPrice > 0 && toTokenPrice > 0, "Token prices not set");

        // Calculate the amount of the destination token that can be obtained
        uint256 amountOut = (amountIn * fromTokenPrice) / toTokenPrice;

        // Check if there are enough reserves to execute the swap
        require(reserves[fromToken] >= amountIn, "Insufficient reserve of fromToken");
        require(reserves[toToken] >= amountOut, "Insufficient reserve of toToken");

        // Perform the swap
        reserves[fromToken] -= amountIn;
        reserves[toToken] += amountOut;

        bool success = IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
        require(success, "From token transfer failed");

        success = IERC20(toToken).transfer(msg.sender, amountOut);
        require(success, "To token transfer failed");

        emit TokenSwapped(fromToken, toToken, amountIn, amountOut);
    }

    // Function to view reserves of a specific token
    function getReserve(address token) external view returns (uint256) {
        return reserves[token];
    }
}
