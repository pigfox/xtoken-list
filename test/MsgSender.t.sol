// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MsgSender} from "../src/MsgSender.sol";

contract MsgSenderTest is Test {
    MsgSender public msgSender;
    address public owner;

    function setUp() public {
        owner = vm.envAddress("WALLET_ADDRESS");
        console.log("Owner Address:", owner);

        // Deploy MsgSender with owner set as WALLET_ADDRESS
        vm.startPrank(owner);
        msgSender = new MsgSender();
        vm.stopPrank();
    }

    function test_run() external{
        vm.startPrank(owner);
        console.log("msg.sender:", msg.sender);
        msgSender.run();
        vm.stopPrank();
    }
}
