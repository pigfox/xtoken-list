// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Dex.sol";

contract DexScript is Script {
    function run() external {
        vm.startBroadcast();

        Dex dex = new Dex();
        dex.setName("2");
        console.log("Dex deployed at:", address(dex));

        vm.stopBroadcast();
    }
}