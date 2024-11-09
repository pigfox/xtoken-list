// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";
import {HelperFctns} from "./HelperFctns.sol";

contract Functions is Test{
    HelperFctns public helperFctns;
    function getTokenBalanceOf(string calldata _tokenAddress, string calldata _holderAddress) public returns (uint256) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = "--rpc-url";
        inputs[3] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[4] = _tokenAddress;
        inputs[5] = "balanceOf(address)";
        inputs[6] = _holderAddress;
        bytes memory result = vm.ffi(inputs);
        console.logBytes(result);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

         uint256 balance = abi.decode(result, (uint256));
         return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (bytes memory transactionHash, bool success) {
        // Prepare inputs for the `cast send` command
        string[] memory inputs = new string[](11);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = "--rpc-url";
        inputs[3] = vm.envString("SEPOLIA_HTTP_RPC_URL"); // RPC URL from environment
        inputs[4] = _tokenAddress;
        inputs[5] = "mint(uint256)";
        inputs[6] = vm.toString(_amount);
        inputs[7] = "--from";
        inputs[8] = vm.envString("WALLET_ADDRESS");
        inputs[9] = "--private-key";
        inputs[10] = vm.envString("PRIVATE_KEY");

        // Execute the command and get the result
        bytes memory result = vm.ffi(inputs);
        console.logBytes(result); // Debugging: Print result bytes

        // Check if result is non-empty and decode
        if (0 < result.length) {
            (transactionHash, success) = abi.decode(result, (bytes, bool));
        } else {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        return (transactionHash, success);
    }

}
