// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Router {
    mapping(address => uint256) public tokenPrices;

    // Get the balance of a specific token held by this contract
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function setTokenPrice(address _token, uint256 _balance) external {
        tokenPrices[_token] = _balance;
    }

    function getTokenPrice(address _token) external view returns (uint256) {
        return tokenPrices[_token];
    }

    // Generic function to swap a specific amount of `tokenIn` for `tokenOut`
    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external {
        require(IERC20(tokenIn).balanceOf(msg.sender) >= amountIn, "Insufficient input token balance");
        require(IERC20(tokenOut).balanceOf(address(this)) >= amountOut, "Insufficient output token liquidity");

        // Transfer input tokens from sender to this contract
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Input token transfer failed");

        // Transfer output tokens from this contract to the sender
        require(IERC20(tokenOut).transfer(msg.sender, amountOut), "Output token transfer failed");
    }

    // Add liquidity for a specific token in the router
    function addLiquidity(address token, uint256 amount) external {
        // Transfer the token from the sender to the contract
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Liquidity addition failed");
        tokenPrices[token] += amount;
    }
}