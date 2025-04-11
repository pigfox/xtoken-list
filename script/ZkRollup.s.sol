// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ZkRollup.sol";

contract ZkRollupScript is Script {
    function run() external {
        vm.startBroadcast();

        ZkRollup zkRollup = new ZkRollup();
        console.log("Vault deployed at:", address(zkRollup));

        vm.stopBroadcast();
    }
}
