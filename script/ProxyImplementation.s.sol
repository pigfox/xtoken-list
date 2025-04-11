// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ProxyImplementation.sol";

contract ProxyImplementationScript is Script {
    function run() external {
        vm.startBroadcast();

        ProxyImplementation proxyImplementation = new ProxyImplementation();
        console.log("ProxyImplementation deployed at:", address(proxyImplementation));

        vm.stopBroadcast();
    }
}
