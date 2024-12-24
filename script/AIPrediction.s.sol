// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/AIPrediction.sol";

contract AIPredictionScript is Script {
    function run() external {
        vm.startBroadcast();

        AIPrediction aIPrediction = new AIPrediction();
        console.log("Vault deployed at:", address(aIPrediction));

        vm.stopBroadcast();
    }
}