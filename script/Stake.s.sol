// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Stake.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();
        address tokenAddress = vm.envAddress("PIGFOX_TOKEN");
        uint256 rewardRate = 1; //vm.envUint256("STAKE_REWARD_RATE");

        Stake stake = new Stake(tokenAddress, rewardRate);
        console.log("Stake deployed at:", address(stake));

        vm.stopBroadcast();
    }
}
