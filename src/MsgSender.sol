// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console} from "../lib/forge-std/src/console.sol";

contract MsgSender {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function run() public view onlyOwner {
        console.log("Run...");
        console.log("Owner:", owner);
        console.log("Msg.Sender:", msg.sender);
    }
}
