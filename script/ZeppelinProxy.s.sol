// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/ZeppelinProxy.sol";

contract ZeppelinProxyScript is Script {
    function run() external {
        address zeppelinImplV1 = vm.envAddress("ZEPPELIN_IMPL_V1");
        address adminWallet = vm.envAddress("WALLET_ADDRESS");
        bytes memory initData = ""; // []byte in Go maps to empty bytes in Solidity

        vm.startBroadcast();

        // Deploy the ZeppelinProxy contract
        ZeppelinProxy zeppelinProxy = new ZeppelinProxy(zeppelinImplV1, adminWallet, initData);

        console.log("ZeppelinProxy deployed at:", address(zeppelinProxy));

        vm.stopBroadcast();
    }
}
