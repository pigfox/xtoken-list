// SPDX-License-Identifier: MIT
//Simulates an ERC20 token
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract ERC20Token is ERC20 {
    address public owner;
    uint private initialSupply;
    //ERC20Token public erc20Token;

    constructor(uint256 _initialSupply) ERC20("XToken", "XTK") {
        owner = msg.sender;
        _mint(owner, _initialSupply);
        console.log("_initialSupply", _initialSupply);
    }

    function getSuppy() public view returns (uint256) {
        return this.totalSupply();
    }

    function mint(uint256 _amount) public {
        _mint(owner, _amount);
    }

    function supplyToken(address _to, uint256 _amount) external {
        _mint(owner, _amount);
        IERC20 token = IERC20(address(this));
        token.approve(_to, _amount);
        token.transfer(_to, _amount);
    }
}
