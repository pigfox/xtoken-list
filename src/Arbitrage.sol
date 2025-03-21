// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDex {
    function getPrice(address tokenB) external view returns (uint256);
}

contract Arbitrage {
    address public owner;
    address public profitAddress;

    // Mapping to track access rights
    mapping(address => bool) public accessors;

    constructor() {
        owner = msg.sender;
        profitAddress = msg.sender;
        accessors[msg.sender] = true; // Grant access to the owner by default
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Arbitrage - Not the owner");
        _;
    }

    modifier onlyAccessor() {
        require(accessors[msg.sender], "Arbitrage - Not an authorized accessor");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setProfitAddress(address _profitAddress) external onlyOwner {
        profitAddress = _profitAddress;
    }

    // Add an address to the group of accessors
    function addAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = true;
    }

    // Remove an address from the group of accessors
    function removeAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = false;
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
    ) external onlyAccessor {
        // Check if the transaction is within the deadline
        require(block.timestamp <= deadline, "Transaction deadline exceeded");

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
/*
 (e.g., reentrancy, overflow/underflow, front-running).
*/