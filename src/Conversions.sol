// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console} from "../lib/forge-std/src/console.sol";

contract Conversions {
    event LogDataLength(uint256 length);
    function addressToString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function hexToUint(string memory _hex) public pure returns (uint256) {
        bytes memory b = bytes(_hex);
        uint256 result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint8 charCode = uint8(b[i]);  // Convert bytes1 to uint8 for comparison
            if (charCode >= 0x30 && charCode <= 0x39) {
                result = result * 16 + (charCode - 0x30);
            } else if (charCode >= 0x41 && charCode <= 0x46) {
                result = result * 16 + (charCode - 0x41 + 10);
            } else if (charCode >= 0x61 && charCode <= 0x66) {
                result = result * 16 + (charCode - 0x61 + 10);
            }
        }
        return result;
    }

    function bytes32ToString(bytes32 _data) public pure returns (string memory) {
        bytes memory tempBytes = new bytes(32);
        uint8 length = 0;

        for (uint8 i = 0; i < 32; i++) {
            bytes1 char = _data[i]; // Use bytes1 instead of byte
            if (char != 0) {
                tempBytes[length] = char;
                length++;
            } else {
                break;
            }
        }

        bytes memory result = new bytes(length);
        for (uint8 j = 0; j < length; j++) {
            result[j] = tempBytes[j];
        }

        return string(result);
    }

    function bytesToBool(bytes memory data) public pure returns (bool) {
        // If the first byte is non-zero, return true; otherwise, return false.
        return data.length > 0 && data[0] != 0;
    }

    // Helper function to convert a nibble (half-byte) to its hex character
    function byteToHexChar(uint8 nibble) public pure returns (bytes1) {
        if (nibble < 10) {
            return bytes1(nibble + 0x30);  // Converts 0-9 to '0'-'9'
        } else {
            return bytes1(nibble + 0x41 - 10);  // Converts 10-15 to 'A'-'F'
        }
    }

    function stringFromHex(string memory hexString) public pure returns (bytes32 result) {
        bytes memory temp = bytes(hexString);
        require(temp.length == 66, "Invalid hex string length");  // Ensure the string is 66 characters (for 32-byte hex)

        for (uint256 i = 0; i < 32; i++) {
            result |= (bytes32(uint256(hexCharToUint(temp[2 + i * 2])) << (8 * (31 - i))));
            result |= (bytes32(uint256(hexCharToUint(temp[3 + i * 2])) << (8 * (31 - i - 1))));
        }

        return result;
    }

    // Function to convert a single hex character to uint8
    function hexCharToUint(bytes1 hexChar) public pure returns (uint8) {
        if (hexChar >= 0x30 && hexChar <= 0x39) {
            return uint8(hexChar) - 0x30; // 0-9
        } else if (hexChar >= 0x41 && hexChar <= 0x46) {
            return uint8(hexChar) - 0x41 + 10; // A-F
        } else {
            revert("Invalid hex character");
        }
    }

    function hexCharToUint(uint8 c) internal pure returns (uint8) {
        if (c >= 0x30 && c <= 0x39) return c - 0x30;  // '0' to '9'
        if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;  // 'a' to 'f'
        if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;  // 'A' to 'F'
        revert("Invalid hex char");
    }

    // Helper function to parse hex string to bytes32
    function bytes32FromHex(bytes memory hexValue) public pure returns (bytes32 result) {
        require(hexValue.length == 66, "Invalid bytes32 length");
        for (uint i = 0; i < 32; i++) {
            uint8 digit1 = hexCharToUint(uint8(hexValue[2 + i * 2])); // Convert bytes1 to uint8
            uint8 digit2 = hexCharToUint(uint8(hexValue[3 + i * 2])); // Convert bytes1 to uint8
            result |= bytes32(uint256(digit1 * 16 + digit2) << (248 - i * 8));
        }

        return result;
    }

    // Convert a bytes array to its ASCII string representation
    function bytesToString(bytes memory hexValue) public pure returns (string memory) {
        bytes memory strBytes = new bytes(hexValue.length * 2); // Two hex characters per byte
        bytes memory hexAlphabet = "0123456789abcdef";

        for (uint256 i = 0; i < hexValue.length; i++) {
            uint8 byteValue = uint8(hexValue[i]);
            strBytes[i * 2] = hexAlphabet[byteValue >> 4];     // High nibble
            strBytes[i * 2 + 1] = hexAlphabet[byteValue & 0x0f]; // Low nibble
        }

        return string(strBytes); // Convert the bytes array to a string
    }

    function stringFromHex(bytes memory hexValue) public pure returns (string memory) {
        // Ensure the input hexValue has even length
        require(hexValue.length % 2 == 0, "Invalid hex string length");

        // Create a new string of half the length of hexValue because each byte of the hex string
        // represents two characters
        bytes memory result = new bytes(hexValue.length / 2);

        for (uint i = 0; i < hexValue.length / 2; i++) {
            // Convert each pair of hex digits to a byte
            result[i] = byteFromHex(uint8(hexValue[i * 2]), uint8(hexValue[i * 2 + 1])); // Convert bytes1 to uint8
        }

        return string(result);
    }

    // Helper function to convert a pair of hex characters into a single byte
    function byteFromHex(uint8 hex1, uint8 hex2) internal pure returns (bytes1) {
        return bytes1(hexCharToUint(hex1) * 16 + hexCharToUint(hex2));
    }

    // Convert a string to its hexadecimal representation
    function stringToHex(string memory str) public pure returns (string memory) {
        bytes memory strBytes = bytes(str); // Convert the input string to bytes
        bytes memory hexBytes = new bytes(2 + strBytes.length * 2); // "0x" + 2 hex chars per byte

        hexBytes[0] = "0";
        hexBytes[1] = "x";

        bytes memory hexAlphabet = "0123456789abcdef";

        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 byteValue = uint8(strBytes[i]);
            hexBytes[2 + i * 2] = hexAlphabet[byteValue >> 4];      // High nibble
            hexBytes[3 + i * 2] = hexAlphabet[byteValue & 0x0f];    // Low nibble
        }

        return string(hexBytes); // Return the hexadecimal representation as a string
    }

    function bytesToHex(bytes memory data) public returns (string memory) {
        console.log("#170");
        emit LogDataLength(data.length);
        bytes memory result = new bytes(data.length * 2);
        //bytes memory hexAlphabet = "0123456789abcdef";
        console.log("data.length:", data.length);
        /*
        for (uint256 i = 0; i < data.length; i++) {
            uint8 byteValue = uint8(data[i]);
            result[i * 2] = hexAlphabet[byteValue >> 4];      // High nibble
            result[i * 2 + 1] = hexAlphabet[byteValue & 0x0f]; // Low nibble
        }
*/
        return string(result); // Convert the bytes array to a string
    }
}