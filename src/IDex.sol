// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IDex {
    function depositTokens(address token, uint256 amount) external;
    function buyTokens(address token, uint256 amount) external payable returns (uint256);
    function sellTokens(address token, uint256 amount) external returns (uint256);
    function setTokenPrice(address token, uint256 price) external;
    function getTokenPrice(address token) external view returns (uint256);
    function withdraw(address token, uint256 amount) external; // Added
}