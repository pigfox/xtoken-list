// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/AAVE.sol";

contract AAVEScript is Script {
    function run() external {
        vm.startBroadcast();

        AAVE aAVE = new AAVE();
        console.log("AAVE deployed at:", address(aAVE));

        vm.stopBroadcast();
    }
}
