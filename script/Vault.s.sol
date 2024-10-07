// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Vault.sol";

contract VaultScript is Script {
    function run() external {
        vm.startBroadcast();

        Vault vault = new Vault();
        console.log("Vault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}