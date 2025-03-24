// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Arbitrage.sol";

contract ArbitrageLocalScript is Script {
    function run() external {
        // Read the vault address from the .env file
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");

        vm.startBroadcast();
        Arbitrage arbitrage = new Arbitrage(vaultAddress);
        console.log("Arbitrage deployed at:", address(arbitrage));
        vm.stopBroadcast();
    }
}