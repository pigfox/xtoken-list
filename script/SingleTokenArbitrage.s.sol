// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/SingleTokenArbitrage.sol";

contract SingleTokenArbitrageScript is Script {
    function run() external {
        vm.startBroadcast();

        SingleTokenArbitrage singleTokenArbitrage = new SingleTokenArbitrage();
        console.log("Vault deployed at:", address(singleTokenArbitrage));

        vm.stopBroadcast();
    }
}