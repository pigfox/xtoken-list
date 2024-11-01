// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MsgSender} from "../src/MsgSender.sol";

contract MsgSenderTest is Test {
    MsgSender msgSender;
    address owner;

    function setUp() public {
        owner = vm.envAddress("WALLET_ADDRESS");
        console.log("Owner Address:", owner);
        vm.startPrank(owner);
        msgSender = new MsgSender();
    }

    function test_run() external view{
        msgSender.run();
    }

    function tearDown() public {
        vm.stopPrank(); // Ensure prank is stopped after each test
    }
}
