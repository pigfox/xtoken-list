// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/MaliciousReentrancy.sol";

contract MaliciousReentrancyScript is Script {
    function run() external {
        vm.startBroadcast();
        address donationManager = vm.envAddress("DONATION_MANAGER");

        MaliciousReentrancy maliciousReentrancy = new MaliciousReentrancy(donationManager);
        console.log("MaliciousReentrancy deployed at:", address(maliciousReentrancy));

        vm.stopBroadcast();
    }
}
