// SPDX-License-Identifier: MIT
//Simulates an ERC20 token
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract ERC20Token is ERC20 {
    address public owner;

    constructor() ERC20("XToken", "XTK") {
        owner = msg.sender;
    }

    function getSuppy() public view returns (uint256) {
        return this.totalSupply();
    }

    function mint(uint256 _amount) public {
        _mint(owner, _amount);
    }

    function supplyToken(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function getBalance(address _account) public view returns (uint256) {
        return this.balanceOf(_account);
    }
}
