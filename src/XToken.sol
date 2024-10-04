// SPDX-License-Identifier: MIT
//Simulates an ERC20 token
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract XToken is ERC20 {
    address public owner;
    uint private initialSupply;
    IERC20 public token;

    constructor(uint256 _initialSupply) ERC20("XToken", "XTK") {
        owner = msg.sender;
        _mint(address(this), _initialSupply);
        console.log("_initialSupply", _initialSupply);
    }

    modifier onlyOwner()virtual {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function supply(address _destination, uint256 _amount) external {
        console.log("Available tokens", this.balanceOf(address(this)));
        require(this.balanceOf(address(this)) >= _amount, "Not enough tokens");
        console.log("_destination", _destination);
        console.log("_amount", _amount);

        // Transfer tokens directly using ERC20 transfer function
        _transfer(address(this), _destination, _amount);
        console.log("Tokens transferred successfully");
    }
}
