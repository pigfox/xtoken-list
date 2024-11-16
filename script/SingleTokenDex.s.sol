// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/SingleTokenDex.sol";

contract SingleTokenDexScript is Script {
    function run() external {
        vm.startBroadcast();

        SingleTokenDex singleTokenDex = new SingleTokenDex();
        console.log("Vault deployed at:", address(singleTokenDex));

        vm.stopBroadcast();
    }
}