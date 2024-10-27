// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault {
    mapping(address => uint256) public tokenPrices;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Function to get the balance of a specific ERC20 token held by the contract
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    // Function to get the ETH balance of the contract
    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to allow the contract to receive ETH
    receive() external payable {}

    // Fallback function to allow the contract to receive ETH
    fallback() external payable {}
}
