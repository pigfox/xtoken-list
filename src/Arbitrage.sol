// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {console} from "../lib/forge-std/src/console.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IDexRouter {
    function getTokenBalance(address token) external view returns (uint256);
}

contract Arbitrage {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Approves the routers to spend XToken
    function _approveRouters(address xToken, address fromRouter, address toRouter, uint256 amount) internal {
        console.log("Approving routers");
        bool fromRouterApproved = IERC20(xToken).approve(fromRouter, amount);
        require(fromRouterApproved, "From router approval failed");
        console.log("From router approved successfully");
        bool toRouterApproved = IERC20(xToken).approve(toRouter, amount);
        require(toRouterApproved, "To router approval failed");
        console.log("To router approved successfully");
        bool arbitrageApproved = IERC20(xToken).approve(address(this), amount);
        require(arbitrageApproved, "Arbitrage approval failed");
        console.log("Arbitrage approved successfully");
        console.log("Routers approved successfully");
    }

    // Perform arbitrage if profitable
    function executeArbitrage(
        address xToken,
        address fromRouterAddress,
        address toRouterAddress,
        address profitRecipient,
        uint256 amount
    ) external onlyOwner {
        console.log("Executing arbitrage");
        _approveRouters(xToken, fromRouterAddress, toRouterAddress, amount);
        uint256 initialBalance = IERC20(xToken).balanceOf(fromRouterAddress);
        require(initialBalance >= amount, "Insufficient balance in fromRouter");

        ERC20 token = ERC20(xToken);
        token.approve(fromRouterAddress, amount);
        token.transferFrom(fromRouterAddress, address(this), amount);
        uint256 amountBReceived = IERC20(xToken).balanceOf(address(this));
        token.approve(address(this), amount);
        token.transferFrom(address(this), toRouterAddress, amountBReceived);

        // Calculate the profit made from the arbitrage trade
        uint256 finalBalance = IERC20(xToken).balanceOf(address(this));
        uint256 profit = finalBalance > initialBalance ? finalBalance - initialBalance : 0;

        // Send the profit to the profit recipient
        if (profit > 0) {
            require(IERC20(xToken).transfer(profitRecipient, profit), "Profit transfer failed");
        }
    }

    // Withdraw any token from the contract (including XToken and other tokens)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}