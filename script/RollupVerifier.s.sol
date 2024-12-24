// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/RollupVerifier.sol";

contract RollupVerifierScript is Script {
    function run() external {
        vm.startBroadcast();

        RollupVerifier rollupVerifier = new RollupVerifier();
        console.log("Vault deployed at:", address(rollupVerifier));

        vm.stopBroadcast();
    }
}