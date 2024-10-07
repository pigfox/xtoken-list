// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ERC20Token.sol";

contract ERC20TokenScript is Script {
    function run() external {
        vm.startBroadcast();

        ERC20Token erc20Token = new ERC20Token();
        console.log("ERC20Token deployed at:", address(erc20Token));

        vm.stopBroadcast();
    }
}