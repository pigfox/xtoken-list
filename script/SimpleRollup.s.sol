// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/SimpleRollup.sol";

contract SimpleRollupScript is Script {
    function run() external {
        vm.startBroadcast();

        SimpleRollup simpleRollup = new SimpleRollup();
        console.log("SimpleRollup deployed at:", address(simpleRollup));

        vm.stopBroadcast();
    }
}