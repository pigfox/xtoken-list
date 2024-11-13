// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Router} from "../src/Router.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {TransactionReceipt} from "../src/TransactionReceipt.sol";
import {XToken} from "../src/XToken.sol";
import {console} from "../lib/forge-std/src/console.sol";


contract FunctionsTest is Test{
    ConversionsTest public conversionsTest;
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

    constructor() {
        conversionsTest = new ConversionsTest();
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory){
        console.log("Minting ", _amount, "tokens");
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

        bytes memory result = vm.ffi(inputs);
        if (0 == result.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }
        string memory resultString = string(result);
        console.log("Cast result",resultString);

        string[] memory jqStatusCmd = new string[](4);
        jqStatusCmd[0] = "jq";
        jqStatusCmd[1] = "-r";
        jqStatusCmd[2] = ".status";
        jqStatusCmd[3] = resultString;
        bytes memory statusBytes = vm.ffi(jqStatusCmd);
        string memory statusString = string(statusBytes);

        string[] memory jqTxHashCmd = new string[](4);
        jqTxHashCmd[0] = "jq";
        jqTxHashCmd[1] = "-r";
        jqTxHashCmd[2] = "transactionHash";
        jqTxHashCmd[3] = resultString;
        bytes memory txHashBytes = vm.ffi(jqTxHashCmd);
        string memory txHashString = string(txHashBytes);

        if(bytes(statusString).length == 0 || bytes(txHashString).length == 0){
            console.log("Error: json conversion failed");
            revert("Error: json conversion failed");
        }

        // Log the status and transactionHash as strings
        console.log("Transaction Status: ", statusString);
        console.log("Transaction Hash: ", txHashString);

        return(txHashString,statusString);
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
