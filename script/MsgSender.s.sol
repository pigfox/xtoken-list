// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/MsgSender.sol";

contract MsgSenderScript is Script {
    function run() external {
        vm.startBroadcast();
        MsgSender msgSender = new MsgSender();
        console.log("MsgSender deployed at:", address(msgSender));

        vm.stopBroadcast();
    }
}
