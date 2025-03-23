// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDex.sol"; // Use generic interface

contract Arbitrage {
    address public owner;
    address public profitAddress;
    mapping(address => bool) public accessors;

    constructor() {
        owner = msg.sender;
        profitAddress = msg.sender;
        accessors[msg.sender] = true; // Owner has access by default
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAccessor() {
        require(accessors[msg.sender], "Not an authorized accessor");
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

    function addAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = true;
    }

    function removeAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = false;
    }

    // Approve tokens for spending by a DEX
    function _approveToken(address token, address dex, uint256 amount) internal {
        require(IERC20(token).approve(dex, amount), "Token approval failed");
    }

    // Execute arbitrage: Buy from cheaper DEX, sell to expensive DEX
    function run(
        address token,
        address dexCheap, // DEX with lower price (buy here)
        address dexExpensive, // DEX with higher price (sell here)
        uint256 amount, // Amount of tokens to trade
        uint256 deadline
    ) external onlyAccessor {
        require(block.timestamp <= deadline, "Transaction deadline exceeded");

        // Get prices from both DEXes
        uint256 priceCheap = IDex(dexCheap).getTokenPrice(token);
        uint256 priceExpensive = IDex(dexExpensive).getTokenPrice(token);
        require(priceCheap < priceExpensive, "No arbitrage opportunity");

        // Calculate ETH needed to buy tokens from cheap DEX
        uint256 ethToSpend = (amount * priceCheap) / 10**18; // Assumes price is in wei per token
        require(address(this).balance >= ethToSpend, "Insufficient ETH in contract");

        // Buy tokens from cheaper DEX
        uint256 tokensBought = IDex(dexCheap).buyTokens{value: ethToSpend}(token, amount);
        require(tokensBought >= amount, "Failed to buy enough tokens");

        // Approve expensive DEX to take tokens
        _approveToken(token, dexExpensive, tokensBought);

        // Sell tokens to expensive DEX
        uint256 ethReceived = IDex(dexExpensive).sellTokens(token, tokensBought);

        // Calculate and transfer profit
        uint256 profit = ethReceived > ethToSpend ? ethReceived - ethToSpend : 0;
        if (profit > 0) {
            (bool sent, ) = profitAddress.call{value: profit}("");
            require(sent, "Profit transfer failed");
        }
    }

    // Withdraw tokens or ETH (for owner cleanup)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
    }

    // Allow contract to receive ETH
    receive() external payable {}
}