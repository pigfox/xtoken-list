// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Airdrop.sol";

contract AirdropScript is Script {
    function run() external {
        vm.startBroadcast();
        Airdrop airdrop = new Airdrop();
        console.log("Airdrop deployed at:", address(airdrop));
        vm.stopBroadcast();
    }
}
