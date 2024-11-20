// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract ConversionsTest is Test  {
    // Function to convert a string to an address
    function stringToAddress(string memory _tokenAddress) public pure returns (address) {
        bytes memory addressBytes = bytes(_tokenAddress);
        require(addressBytes.length == 42, "Invalid address length");
        require(addressBytes[0] == '0' && (addressBytes[1] == 'x' || addressBytes[1] == 'X'), "Invalid address format");

        uint160 addr = 0;
        for (uint256 i = 2; i < 42; i++) {
            uint8 b = uint8(addressBytes[i]);
            if (b >= 48 && b <= 57) { // '0' to '9'
                addr = addr * 16 + (b - 48);
            } else if (b >= 97 && b <= 102) { // 'a' to 'f'
                addr = addr * 16 + (b - 87);
            } else if (b >= 65 && b <= 70) { // 'A' to 'F'
                addr = addr * 16 + (b - 55);
            } else {
                revert("Invalid address character");
            }
        }
        return address(addr);
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

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;

        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);

            // Check if the character is 0-9
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48); // Base 10 conversion
            } else {
                revert("Invalid character: not a number");
            }
        }

        return result;
    }

    function uintToString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}