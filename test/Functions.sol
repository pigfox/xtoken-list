// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Router} from "../src/Router.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
//import {TransactionReceipt} from "../src/TransactionReceipt.sol";
import {XToken} from "../src/XToken.sol";
import {console} from "../lib/forge-std/src/console.sol";


contract FunctionsTest is Test{

    struct LogEntry {
        address addr;
        bytes32[] topics;
        bytes data;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes32 transactionHash;
        uint256 transactionIndex;
        uint256 logIndex;
        bool removed;
    }

    struct TransactionReceipt {
        string status;
        uint256 cumulativeGasUsed;
        LogEntry[] logs;
        bytes logsBloom;
        uint8 txType;
        string transactionHash;
        uint256 transactionIndex;
        bytes32 blockHash;
        uint256 blockNumber;
        uint256 gasUsed;
        uint256 effectiveGasPrice;
        address from;
        address to;
        address contractAddress; // Nullable field represented as an address
    }
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
        string memory json = string(result);
        (string memory status, string memory transactionHash) = parseJson(json);

        return (transactionHash,status);
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

    function parseJson(string memory json) internal pure returns (string memory status, string memory transactionHash) {
        bytes memory jsonBytes = bytes(json);

        uint256 statusStart = findIndexOfSubstring(jsonBytes, '"status":"', 0) + 10;
        uint256 statusEnd = findIndexOfSubstring(jsonBytes, '"', statusStart);
        status = extractSubstring(json, statusStart, statusEnd);

        uint256 txHashStart = findIndexOfSubstring(jsonBytes, '"transactionHash":"', 0) + 19;
        uint256 txHashEnd = findIndexOfSubstring(jsonBytes, '"', txHashStart);
        transactionHash = extractSubstring(json, txHashStart, txHashEnd);
        return (status, transactionHash);
    }

// Helper function to find the position of a substring starting from a specified index
    function findIndexOfSubstring(bytes memory data, string memory substring, uint256 startIndex)
    internal
    pure
    returns (uint256)
    {
        bytes memory subBytes = bytes(substring);
        uint256 dataLength = data.length;
        uint256 subLength = subBytes.length;

        if (subLength == 0 || dataLength < subLength || startIndex >= dataLength) {
            revert("Invalid substring or start index");
        }

        for (uint256 i = startIndex; i <= dataLength - subLength; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < subLength; j++) {
                if (data[i + j] != subBytes[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                return i;
            }
        }
        revert("Substring not found");
    }

    // Helper function to extract a substring from a string given start and end indices
    function extractSubstring(string memory str, uint256 start, uint256 end)
    internal
    pure
    returns (string memory)
    {
        bytes memory strBytes = bytes(str);
        require(end <= strBytes.length, "Invalid end position");
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }
/*
    // Example usage function to display parsed status and transaction hash
    function displayParsedData(string memory json) public view {
        (string memory status, string memory transactionHash) = parseJson(json);
        console.log("Transaction Status: ", status);
        console.log("Transaction Hash: ", transactionHash);
    }
    */
}
