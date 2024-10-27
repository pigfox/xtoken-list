// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Router.sol";

contract RouterScript is Script {
    function run() external {
        vm.startBroadcast();
        Router router = new Router();
        console.log("Router deployed at:", address(router));

        vm.stopBroadcast();
    }
}