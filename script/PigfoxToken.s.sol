// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/PigfoxToken.sol";

contract PigfoxTokenScript is Script {
    function run() external {
        uint256 maxTokenSupply = 10 ether;
        vm.startBroadcast();

        PigfoxToken pigfoxToken = new PigfoxToken();
        pigfoxToken.mint(maxTokenSupply);
        console.log("PigfoxToken deployed at:", address(pigfoxToken));

        vm.stopBroadcast();
    }
}
