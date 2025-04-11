// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Dex {
    address public admin; // Admin address for the DEX
    mapping(address => uint256) public tokenBalances; // Token balances held by the DEX
    mapping(address => uint256) public tokenPrices; // Token prices in wei per token unit

    event Deposited(address indexed token, address indexed sender, uint256 amount);
    event Bought(address indexed token, address indexed buyer, uint256 amount, uint256 ethSpent);
    event Sold(address indexed token, address indexed seller, uint256 amount, uint256 ethReceived);
    event PriceSet(address indexed token, uint256 price);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // Deposit tokens into the DEX
    function depositTokens(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        tokenBalances[token] += amount;
        emit Deposited(token, msg.sender, amount);
    }

    // Buy tokens from the DEX with ETH
    function buyTokens(address token, uint256 amount) external payable returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        uint8 decimals = IERC20Metadata(token).decimals();
        uint256 ethRequired = (amount * price) / 10 ** decimals;
        require(msg.value >= ethRequired, "Insufficient ETH sent");
        require(tokenBalances[token] >= amount, "Insufficient token balance");

        tokenBalances[token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

        // Refund excess ETH if any
        if (msg.value > ethRequired) {
            (bool refundSuccess,) = msg.sender.call{ value: msg.value - ethRequired }("");
            require(refundSuccess, "ETH refund failed");
        }

        emit Bought(token, msg.sender, amount, ethRequired);
        return amount;
    }

    // Sell tokens to the DEX for ETH
    function sellTokens(address token, uint256 amount) external returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        uint8 decimals = IERC20Metadata(token).decimals();
        uint256 ethToSend = (amount * price) / 10 ** decimals;
        require(address(this).balance >= ethToSend, "Insufficient ETH balance");

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        tokenBalances[token] += amount;

        // Send ETH with a gas limit to ensure receiver can execute minimal logic
        (bool success,) = msg.sender.call{ value: ethToSend, gas: 30000 }("");
        require(success, "ETH transfer failed");

        emit Sold(token, msg.sender, amount, ethToSend);
        return ethToSend;
    }

    // Set the price of a token
    function setTokenPrice(address token, uint256 price) external onlyAdmin {
        require(price > 0, "Price must be greater than 0");
        tokenPrices[token] = price;
        emit PriceSet(token, price);
    }

    // Get the price of a token
    function getTokenPrice(address token) external view returns (uint256) {
        return tokenPrices[token];
    }

    // Withdraw tokens or ETH from the DEX (for testing or admin purposes)
    function withdraw(address token, uint256 amount) external {
        if (token == address(0)) {
            // Withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success,) = msg.sender.call{ value: amount }("");
            require(success, "ETH withdrawal failed");
        } else {
            // Withdraw tokens
            require(tokenBalances[token] >= amount, "Insufficient token balance");
            tokenBalances[token] -= amount;
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }
        emit Withdrawn(token, msg.sender, amount);
    }

    // Accept ETH deposits
    receive() external payable { }
}
