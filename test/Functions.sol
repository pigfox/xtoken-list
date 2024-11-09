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
        //cast call "$XToken" "balanceOf(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url"
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = _tokenAddress;
        inputs[3] = "balanceOf(address)";
        inputs[4] = _holderAddress;
        inputs[5] = "--rpc-url";
        inputs[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

         uint256 balance = abi.decode(result, (uint256));
         return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (bytes memory output) {
        // cast send "$XToken" "mint(uint256)" 100000088840000000000667 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](11);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _tokenAddress;
        inputs[3] = "mint(uint256)";
        inputs[4] = vm.toString(_amount);
        inputs[5] = "--rpc-url";
        inputs[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[7] = "--from";
        inputs[8] = vm.envString("WALLET_ADDRESS");
        inputs[9] = "--private-key";
        inputs[10] = vm.envString("PRIVATE_KEY");

        // Execute the command and get the result
        bytes memory result = vm.ffi(inputs);
        console.log("Mint result",string(result));

        // Check if result is non-empty before decoding
        if (0 < result.length) {
            output = abi.decode(result, (bytes));
        } else {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        return output;
    }

    function supplyTokensTo(string calldata _supplierAddress, string calldata _receiverAddress, uint256 _amount) public returns (bytes memory output) {
        // cast send "$XToken" "supplyTokenTo(address,uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _supplierAddress;
        inputs[3] = "supplyTokenTo(address,uint256)";
        inputs[4] = _receiverAddress;
        inputs[5] = vm.toString(_amount);
        inputs[6] = "--rpc-url";
        inputs[7] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[8] = "--from";
        inputs[9] = vm.envString("WALLET_ADDRESS");
        inputs[10] = "--private-key";
        inputs[11] = vm.envString("PRIVATE_KEY");

        // Execute the command and get the result
        bytes memory result = vm.ffi(inputs);

        // Check if result is non-empty before decoding
        if (result.length > 0) {
            // Decoding directly without `try`
            output = abi.decode(result, (bytes));
        } else {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        return output;
    }

}
