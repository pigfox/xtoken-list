// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDexRouter {
    function getTokenBalance(address token) external view returns (uint256);
}

contract Arbitrage {
    address public owner;
    address public profitAddress;

    constructor() {
        owner = msg.sender;
        profitAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setProfitAddress(address _profitAddress) external onlyOwner {
        profitAddress = _profitAddress;
    }

    // Approves the routers to spend XToken
    function _approveRouters(address xToken, address fromRouter, address toRouter, uint256 amount) internal {

        bool fromRouterApproved = IERC20(xToken).approve(fromRouter, amount);
        require(fromRouterApproved, "From router approval failed");

        bool toRouterApproved = IERC20(xToken).approve(toRouter, amount);
        require(toRouterApproved, "To router approval failed");

        bool arbitrageApproved = IERC20(xToken).approve(address(this), type(uint256).max);
        require(arbitrageApproved, "Arbitrage approval failed");
    }

    // Perform arbitrage if profitable
    function executeArbitrage(
        address xTokenAddress,
        address fromRouterAddress,
        address toRouterAddress,
        uint256 amount,
        uint256 deadline
    ) external onlyOwner {
        require(block.timestamp <= deadline, "Deadline exceeded");
        _approveRouters(xTokenAddress, fromRouterAddress, toRouterAddress, amount);
        uint256 initialBalance = IERC20(xTokenAddress).balanceOf(fromRouterAddress);
        require(initialBalance >= amount, "Insufficient balance in fromRouter");

        ERC20 token = ERC20(xTokenAddress);
        token.approve(fromRouterAddress, amount);
        bool transferredFromRouterAddress = token.transferFrom(fromRouterAddress, address(this), amount);
        require(transferredFromRouterAddress, "Transfer from fromRouter failed");

        uint256 amountBReceived = IERC20(xTokenAddress).balanceOf(address(this));
        token.approve(address(this), amount);
        bool transferredFromArbitrage = token.transferFrom(address(this), toRouterAddress, amountBReceived);
        require(transferredFromArbitrage, "Transfer from arbitrage failed");

        // Calculate the profit made from the arbitrage trade
        uint256 finalBalance = IERC20(xTokenAddress).balanceOf(address(this));
        uint256 profit = finalBalance > initialBalance ? finalBalance - initialBalance : 0;

        // Send the profit to the profit recipient
        if (profit > 0) {
            require(IERC20(xTokenAddress).transfer(profitAddress, profit), "Profit transfer failed");
        }
    }

    // Withdraw any token from the contract (including XToken and other tokens)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}