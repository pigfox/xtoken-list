// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/MaliciousReentrancy.sol";

contract MaliciousReentrancyScript is Script {
    function run() external {
        vm.startBroadcast();

        // Load the target address
        address rawAddress = vm.envAddress("WALLET_ADDRESS");
        console.log("Raw address from environment:", rawAddress);

        // Cast the address to `payable`
        address payable donationManager = payable(rawAddress);
        console.log("Payable address after casting:", donationManager);

        // Deploy the malicious contract
        MaliciousReentrancy maliciousReentrancy = new MaliciousReentrancy(donationManager);
        console.log("MaliciousReentrancy deployed at:", address(maliciousReentrancy));

        vm.stopBroadcast();
    }
}
