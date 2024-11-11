// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {HelperFctns} from "./HelperFctns.sol";
import {Router} from "../src/Router.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {XToken} from "../src/XToken.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {TransactionReceipt} from "./TransactionReceipt.sol";

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

    function mint(string calldata _tokenAddress, uint256 _amount) public {
        // cast send "$XToken" "mint(uint256)" 100000088840000000000667 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _tokenAddress;
        inputs[3] = "mint(uint256)";
        inputs[4] = vm.toString(_amount);
        inputs[5] = "--json";
        inputs[6] = "--rpc-url";
        inputs[7] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[8] = "--from";
        inputs[9] = vm.envString("WALLET_ADDRESS");
        inputs[10] = "--private-key";
        inputs[11] = vm.envString("PRIVATE_KEY");

        // Execute the command and get the result
        bytes memory result = vm.ffi(inputs);
        //console.log("Cast result",string(result));

        if (0 == result.length) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        bytes memory data = vm.parseJson(string(result));
        //console.logBytes(data);
        TransactionReceipt memory transactionReceipt = abi.decode(data, (TransactionReceipt));
        console.log(62);//<--no error
        console.log("Transaction Hash: ", helperFctns.bytes32ToString(transactionReceipt.transactionHash));//<--Member "bytes32ToString" not found or not visible after argument-dependent lookup in type(HelperFctns).
        //console.logBytes32(transactionReceipt.transactionHash);//<--Member "log" not found or not visible after argument-dependent lookup in type(library console).

        //console.log("Transaction Hash: ", transactionReceipt.transactionHash);
        //console.log("Transaction Status: ", transactionReceipt.status);
/*
        string[] memory jqStatusCmd = new string[](3);
        jqStatusCmd[0] = "jq";
        jqStatusCmd[1] = "-r";
        jqStatusCmd[2] = ".status";

        // Pass the result as input to jq
        bytes memory statusBytes = vm.ffi(jqStatusCmd);
        string memory status = string(statusBytes);
        console.log("Transaction Status: ", status);

        // Parse the 'transactionHash' from result using jq
        string[] memory jqTxHashCmd = new string[](3);
        jqTxHashCmd[0] = "jq";
        jqTxHashCmd[1] = "-r";
        jqTxHashCmd[2] = ".transactionHash";

        // Pass the result as input to jq
        bytes memory txHashBytes = vm.ffi(jqTxHashCmd);
        string memory transactionHash = string(txHashBytes);
        console.log("Transaction Hash: ", transactionHash);
        */
    }

    function supplyTokensTo(string calldata _supplierAddress, string calldata _receiverAddress, uint256 _amount) public returns (bytes memory output) {
        // cast send "$XToken" "supplyTokenTo(address,uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _supplierAddress;
        inputs[3] = "supplyTokenTo(address,uint256)";
        inputs[4] = _receiverAddress;
        inputs[5] = vm.toString(_amount);
        inputs[6] = "--json";
        inputs[7] = "--rpc-url";
        inputs[8] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[9] = "--from";
        inputs[10] = vm.envString("WALLET_ADDRESS");
        inputs[11] = "--private-key";
        inputs[12] = vm.envString("PRIVATE_KEY");

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

        // Parse the status field using jq
        string[] memory jqStatusCmd = new string[](3);
        jqStatusCmd[0] = "jq";
        jqStatusCmd[1] = "-r";
        jqStatusCmd[2] = ".status";

        bytes memory statusBytes = vm.ffi(jqStatusCmd);
        string memory status = string(statusBytes);

        string[] memory jqTxHashCmd = new string[](3);
        jqTxHashCmd[0] = "jq";
        jqTxHashCmd[1] = "-r";
        jqTxHashCmd[2] = ".transactionHash";

        bytes memory txHashBytes = vm.ffi(jqTxHashCmd);
        string memory transactionHash = string(txHashBytes);

        // Log the status and transactionHash as strings
        console.log("Transaction Status: ", status);
        console.log("Transaction Hash: ", transactionHash);

        return output;
    }

}
