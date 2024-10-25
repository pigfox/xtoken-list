// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/PigfoxFlashloan.sol";

contract PigfoxFlashloanScript is Script {
    function run() external {
        address equalizerLenderAddress = vm.envAddress("SEPOLIA_EQUALIZER_LENDER"); // Set in .env

        vm.startBroadcast();

        PigfoxFlashloan pigfoxFlashloan = new PigfoxFlashloan();
        pigfoxFlashloan.setLender(equalizerLenderAddress);
        console.log("Pigfox deployed at:", address(pigfoxFlashloan));

        vm.stopBroadcast();
    }
}