// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Pigfox.sol";

contract PigfoxScript is Script {
    function run() external {
        address equalizerLenderAddress = vm.envAddress("SEPOLIA_EQUALIZER_LENDER"); // Set in .env

        vm.startBroadcast();

        Pigfox pigfox = new Pigfox(equalizerLenderAddress);
        console.log("Pigfox deployed at:", address(pigfox));

        vm.stopBroadcast();
    }
}