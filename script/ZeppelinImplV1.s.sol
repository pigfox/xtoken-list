// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ZeppelinImplV1.sol";

contract  ZeppelinImplV1Script is Script {
    function run() external {
        vm.startBroadcast();

        ZeppelinImplV1 zeppelinImplV1 = new ZeppelinImplV1();
        console.log("ZeppelinImplV1 deployed at:", address(zeppelinImplV1));

        vm.stopBroadcast();
    }
}