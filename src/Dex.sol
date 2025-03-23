// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDex.sol"; // Implements the generic interface

contract Dex is IDex {
    address public owner;
    mapping(address => uint256) public tokenPrices; // Price in wei per token
    mapping(address => uint256) public tokenBalances; // DEX's token reserves

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Set the price of a token in wei (e.g., 80 wei per PFX)
    function setTokenPrice(address token, uint256 price) external onlyOwner {
        tokenPrices[token] = price;
    }

    // Get the price of a token in wei
    function getTokenPrice(address token) external view override returns (uint256) {
        return tokenPrices[token];
    }

    // Buy tokens from the DEX by sending ETH
    function buyTokens(address token, uint256 amount) external payable override returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        uint256 ethRequired = (amount * price) / 10**18; // Adjust for token decimals
        require(msg.value >= ethRequired, "Insufficient ETH sent");
        require(tokenBalances[token] >= amount, "Insufficient token balance in DEX");

        tokenBalances[token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Token transfer failed");

        // Refund excess ETH
        if (msg.value > ethRequired) {
            (bool sent, ) = msg.sender.call{value: msg.value - ethRequired}("");
            require(sent, "ETH refund failed");
        }

        return amount;
    }

    // Sell tokens to the DEX for ETH
    function sellTokens(address token, uint256 amount) external override returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        uint256 ethToSend = (amount * price) / 10**18; // Adjust for token decimals
        require(address(this).balance >= ethToSend, "Insufficient ETH in DEX");

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        tokenBalances[token] += amount;

        (bool sent, ) = msg.sender.call{value: ethToSend}("");
        require(sent, "ETH transfer failed");

        return ethToSend;
    }

    // Deposit tokens into the DEX (for setup)
    function depositTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Deposit failed");
        tokenBalances[token] += amount;
    }

    // Deposit ETH into the DEX (for setup)
    function depositETH() external payable onlyOwner {
        // ETH is added to the contract balance automatically
    }

    // Withdraw tokens or ETH (for owner cleanup)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        tokenBalances[token] -= amount;
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
    }

    receive() external payable {}
}