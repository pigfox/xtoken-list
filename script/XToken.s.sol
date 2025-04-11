// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/XToken.sol";

contract XTokenScript is Script {
    function run() external {
        uint256 maxTokenSupply = 10 ether;
        vm.startBroadcast();

        XToken xToken = new XToken();
        xToken.mint(maxTokenSupply);
        console.log("XToken deployed at:", address(xToken));

        vm.stopBroadcast();
    }
}
