// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";

contract Parser is Test{
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
}
