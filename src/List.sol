// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {XToken} from "../src/XToken.sol";

contract List {
    address public owner;
    IERC20 public token;  // Use ERC20 token directly instead of dex contracts
    XToken private xtoken;
    address public dex1;  // Use as recipient
    address public dex2;  // Use as recipient

    constructor(address _dex1, address _dex2, address _tokenAddress) {
        owner = msg.sender;
        dex1 = _dex1;
        dex2 = _dex2;
        token = IERC20(_tokenAddress);
        // Cast token to XToken to call the supply function
        xtoken = XToken(address(token));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function run(uint _tokenSupply) external {
        uint thisBalance = xtoken.balanceOf(address(this));
        console.log("List: ", thisBalance);
        console.log("dex1: ", token.balanceOf(address(dex1)));

        xtoken.supply(address(this), _tokenSupply);
        console.log("Available tokens @ List", xtoken.balanceOf(address(this)));
        thisBalance = xtoken.balanceOf(address(this));

        console.log("thisBalance: ", thisBalance);
        uint256 sendAmount = thisBalance/2;
        console.log("Send amount: ", sendAmount);
        bool success = xtoken.transfer(address(dex1), sendAmount);
        require(success, "Transfer failed");

        thisBalance = xtoken.balanceOf(address(this));
        console.log("thisBalance: ", thisBalance);
        console.log("dex1: ", token.balanceOf(address(dex1)));
        //--------------------------------------------------------------------------------
        sendAmount = thisBalance/2;
        console.log("Send amount: ", sendAmount);
        success = xtoken.transfer(address(dex2), sendAmount);
        require(success, "Transfer failed");

        thisBalance = xtoken.balanceOf(address(this));
        console.log("thisBalance: ", thisBalance);
        console.log("dex2: ", token.balanceOf(address(dex2)));
    }

}