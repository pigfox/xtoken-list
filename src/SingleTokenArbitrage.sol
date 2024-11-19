// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDexRouter {
    function getPrice(address token) external view returns (uint256);
}

contract SingleTokenArbitrage {
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

    // Set profit recipient address
    function setProfitAddress(address _profitAddress) external onlyOwner {
        profitAddress = _profitAddress;
    }

    // Approves Arbitrage contract to spend tokens
    function _approveToken(address token, address dex, uint256 amount) internal {
        bool success = IERC20(token).approve(dex, amount);
        require(success, "Token approval failed");
    }

    // Perform arbitrage for a single token (XToken) between two DEXes
    function executeArbitrage(
        address token,
        address dex1,
        address dex2,
        uint256 amount,
        uint256 deadline
    ) external onlyOwner {
        // Check if the transaction is within the deadline
        require(block.timestamp <= deadline + 300, "Transaction deadline exceeded");

        uint256 price1 = IDexRouter(dex1).getPrice(token); // Get price on Dex1
        uint256 price2 = IDexRouter(dex2).getPrice(token); // Get price on Dex2

        require(price1 != price2, "Prices are the same, no arbitrage opportunity");

        // Determine source and target DEX
        address fromDex = price1 < price2 ? dex1 : dex2;
        address toDex = price1 < price2 ? dex2 : dex1;

        // Transfer tokens from the source DEX to the Arbitrage contract
        uint256 initialFromDexBalance = IERC20(token).balanceOf(fromDex);
        require(initialFromDexBalance >= amount, "Insufficient balance in source DEX");

        bool transferredFromDex = IERC20(token).transferFrom(fromDex, address(this), amount);
        require(transferredFromDex, "Transfer from source DEX failed");

        // Approve tokens for the target DEX
        _approveToken(token, toDex, amount);

        // Transfer tokens to the target DEX
        bool transferredToDex = IERC20(token).transfer(toDex, amount);
        require(transferredToDex, "Transfer to target DEX failed");

        // Calculate profit
        uint256 profit = IERC20(token).balanceOf(address(this));
        if (profit > 0) {
            require(IERC20(token).transfer(profitAddress, profit), "Profit transfer failed");
        }
    }

    // Withdraw any token from the contract (including XToken)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }
}
