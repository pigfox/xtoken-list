// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    struct Pool {
        uint256 reserveA; // Reserve of token A
        uint256 reserveB; // Reserve of token B
    }

    mapping(address => mapping(address => Pool)) public pools; // Dex -> Token -> Pool

    event LiquidityAdded(address indexed dex, address indexed token, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed dex, address indexed token, uint256 amountA, uint256 amountB);

    // Add liquidity to the DEX
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external {
        Pool storage pool = pools[msg.sender][tokenB];
        pool.reserveA += amountA;
        pool.reserveB += amountB;

        emit LiquidityAdded(msg.sender, tokenB, amountA, amountB);

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer tokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer tokenB failed");
    }

    // Remove liquidity from the DEX
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external {
        Pool storage pool = pools[msg.sender][tokenB];
        require(pool.reserveA >= amountA && pool.reserveB >= amountB, "Insufficient reserves");

        pool.reserveA -= amountA;
        pool.reserveB -= amountB;

        emit LiquidityRemoved(msg.sender, tokenB, amountA, amountB);

        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer tokenA failed");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer tokenB failed");
    }

    // Get the price of token A in terms of token B
    function getPrice(address tokenB) external view returns (uint256) {
        Pool storage pool = pools[msg.sender][tokenB];
        require(pool.reserveA > 0 && pool.reserveB > 0, "Invalid pool reserves");

        return (pool.reserveB * 1e18) / pool.reserveA; // Price of 1 A in terms of B
    }
}
