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
    function run(
        address token,
        address dex1,
        address dex2,
        uint256 amount,
        uint256 deadline
    ) external onlyOwner {
        // Check if the transaction is within the deadline
        require(block.timestamp <= deadline, "Transaction deadline exceeded");
        // Get prices from DEXes
        //uint256 dex1price = IDex(dex1).getPrice(token); // Price of XToken on Dex1
        //uint256 dex2price = IDex(dex2).getPrice(token); // Price of XToken on Dex2

        // Approve DEXes to spend tokens
        _approveToken(token, dex1, amount);
        _approveToken(token, dex2, amount);

        // Transfer from Dex1 to Arbitrage contract
        require(
            IERC20(token).transferFrom(dex1, address(this), amount),
            "Transfer from Dex1 failed"
        );

        // Swap from Arbitrage to Dex2
        require(
            IERC20(token).transfer(dex2, amount),
            "Transfer to Dex2 failed"
        );

        // Calculate the profit
        uint256 finalBalance = IERC20(token).balanceOf(address(this));
        uint256 profit = finalBalance > amount ? finalBalance - amount : 0;

        // Send the profit to the profit address
        if (profit > 0) {
            require(IERC20(token).transfer(profitAddress, profit), "Profit transfer failed");
        }
    }

    // Withdraw any token from the contract
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }
}
