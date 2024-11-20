// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/TrashCan.sol";

contract TrashCanScript is Script {
    function run() external {
        vm.startBroadcast();

        TrashCan trashCan = new TrashCan();
        console.log("Vault deployed at:", address(trashCan));

        vm.stopBroadcast();
    }
}