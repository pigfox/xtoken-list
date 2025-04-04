// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/OptimisticRollupFraudProof.sol";

contract OptimisticRollupFraudProofScript is Script {
    function run() external {
        vm.startBroadcast();

        OptimisticRollupFraudProof optimisticRollupFraudProof = new OptimisticRollupFraudProof();
        console.log("OptimisticRollupFraudProof deployed at:", address(optimisticRollupFraudProof));

        vm.stopBroadcast();
    }
}