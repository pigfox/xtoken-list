// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ZeppelinProxyHelper.sol";

contract  ZeppelinProxyHelperScript is Script {
    function run() external {
        vm.startBroadcast();

        ZeppelinProxyHelper zeppelinProxyHelper = new ZeppelinProxyHelper();
        console.log("ZeppelinProxyHelper deployed at:", address(zeppelinProxyHelper));

        vm.stopBroadcast();
    }
}