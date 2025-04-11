// SPDX-License-Identifier: MIT
//Simulates an ERC20 token
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XToken is ERC20 {
    event Minted(uint256 amount, address sender);
    event MintedTo(uint256 amount, address receiver);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() ERC20("PigfoxToken", "PFX") {
        owner = msg.sender;
    }

    function updateOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Approve the spender to spend tokens on behalf of the owner
    function approveSpender(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function mint(uint256 _amount) public {
        _mint(owner, _amount);
        emit Minted(_amount, msg.sender);
    }

    function supplyTokenTo(address _to, uint256 _amount) public {
        _mint(_to, _amount);
        emit MintedTo(_amount, _to);
    }

    function getTokenBalanceAt(address _account) public view returns (uint256) {
        return this.balanceOf(_account);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
