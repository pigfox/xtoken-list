// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ZeppelinImplV2.sol";

contract ZeppelinImplV2Script is Script {
    function run() external {
        vm.startBroadcast();

        ZeppelinImplV2 zeppelinImplV2 = new ZeppelinImplV2();
        console.log("ZeppelinImplV2 deployed at:", address(zeppelinImplV2));

        vm.stopBroadcast();
    }
}
