// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/DonationManager.sol";

contract DonationManagerScript is Script {
    function run() external {
        vm.startBroadcast();
        address donationReceiver = vm.envAddress("WALLET_ADDRESS");

        DonationManager donationManager = new DonationManager(donationReceiver);
        console.log("DonationManager deployed at:", address(donationManager));

        vm.stopBroadcast();
    }
}