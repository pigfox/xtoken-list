// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Arbitrage.sol";

contract ArbitrageScript is Script {
    function run() external {
        vm.startBroadcast();
        Arbitrage arbitrage = new Arbitrage();
        console.log("Arbitrage deployed at:", address(arbitrage));

        vm.stopBroadcast();
    }
}