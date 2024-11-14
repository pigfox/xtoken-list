// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Router} from "../src/Router.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
//import {TransactionReceipt} from "../src/TransactionReceipt.sol";
import {XToken} from "../src/XToken.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";



contract FunctionsTest is Test{
    using stdJson for string;

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

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }
        string memory json = string(castResult);

        string memory result = string(
            abi.encodePacked(json)
        );

        bytes memory status = result.parseRaw(".status");
        uint256[] memory values = abi.decode(status, (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory statusStr = toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);

        return(transactionHashStr,statusStr);
    }

    function supplyTokensTo(string calldata _supplierAddress, string calldata _receiverAddress, uint256 _amount) public returns (string memory, string memory) {
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

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }
        string memory json = string(castResult);

        string memory result = string(
            abi.encodePacked(json)
        );

        bytes memory status = result.parseRaw(".status");
        uint256[] memory values = abi.decode(status, (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory statusStr = toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);

        return(transactionHashStr,statusStr);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    function toHexString(uint256 a) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(abi.encodePacked("0x", string(res)));
    }

/*
    function parseField(string memory json, string memory field, uint fieldLength) internal pure returns (string memory value) {
        bytes memory jsonBytes = bytes(json);
        uint256 statusStart = findIndexOfSubstring(jsonBytes, field, 0) + fieldLength;
        uint256 statusEnd = findIndexOfSubstring(jsonBytes, '"', statusStart);
        value = extractSubstring(json, statusStart, statusEnd);
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
    */
}
