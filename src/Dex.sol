// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public tokenPrice;
    address public owner;

    event TokensDeposited(address indexed tokenAddress, uint256 amount);
    event TokenPriceSet(address indexed tokenAddress, uint256 price);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function updateOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function setTokenPrice(address _address, uint256 _newPrice) public onlyOwner{
        tokenPrice[_address] = _newPrice;
        emit TokenPriceSet(_address, _newPrice);
    }

    function getTokenPriceOf(address _address) external view returns (uint256) {
        return tokenPrice[_address];
    }

    function getTokenBalanceOf(address _address) external view returns (uint256) {
        return tokenBalance[_address];
    }

    function depositTokens(address _token, address _source, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        bool success = IERC20(_token).transferFrom(_source, address(this), _amount);
        require(success, "Token transfer failed");

        tokenBalance[_token] += _amount;
        emit TokensDeposited(_token, _amount);
    }

    function withdrawTokens(address _token, address _destination, uint256 _amount) external onlyOwner{
        require(_amount > 0 && tokenBalance[_token] >= _amount, "Insufficient balance");
        tokenBalance[_token] -= _amount;

        bool success = IERC20(_token).transfer(_destination, _amount);
        require(success, "Token transfer failed");
    }

    function approveTokenTransfer(address token, address spender, uint256 amount) public onlyOwner {
        IERC20(token).approve(spender, amount);
    }

    // Allow the contract to receive ETH
    receive() external payable {}
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
    }
}
