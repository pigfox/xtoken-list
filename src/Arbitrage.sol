// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDex {
    function getPrice(address tokenB) external view returns (uint256);
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

    // Approve tokens for DEXes
    function _approveToken(address token, address dex, uint256 amount) internal {
        require(IERC20(token).approve(dex, amount), "Token approval failed");
    }

    // Execute arbitrage if Dex1 price < Dex2 price
    function executeArbitrage(
        address dex1,
        address dex2,
        address xToken,
        uint256 amount
    ) external onlyOwner {
        // Get prices from DEXes
        uint256 price1 = IDex(dex1).getPrice(xToken); // Price of XToken on Dex1
        uint256 price2 = IDex(dex2).getPrice(xToken); // Price of XToken on Dex2

        require(price1 < price2, "No arbitrage opportunity");

        // Approve DEXes to spend tokens
        _approveToken(xToken, dex1, amount);
        _approveToken(xToken, dex2, amount);

        // Transfer from Dex1 to Arbitrage contract
        require(
            IERC20(xToken).transferFrom(dex1, address(this), amount),
            "Transfer from Dex1 failed"
        );

        // Swap from Arbitrage to Dex2
        require(
            IERC20(xToken).transfer(dex2, amount),
            "Transfer to Dex2 failed"
        );

        // Calculate the profit
        uint256 finalBalance = IERC20(xToken).balanceOf(address(this));
        uint256 profit = finalBalance > amount ? finalBalance - amount : 0;

        // Send the profit to the profit address
        if (profit > 0) {
            require(IERC20(xToken).transfer(profitAddress, profit), "Profit transfer failed");
        }
    }

    // Withdraw any token from the contract
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }
}
