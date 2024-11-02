// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MsgSender {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function run() external view onlyOwner {
        // Do something...
    }
}
