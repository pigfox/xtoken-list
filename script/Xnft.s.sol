// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Xnft.sol";

contract XnftScript is Script {
    function run() external {
        vm.startBroadcast();

        Xnft xnft = new Xnft();
        console.log("Xnft deployed at:", address(xnft));

        vm.stopBroadcast();
    }
}