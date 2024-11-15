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

        // Start iterating after "0x" if present
        uint256 startIndex = (b[0] == '0' && b[1] == 'x') ? 2 : 0;

        for (uint256 i = startIndex; i < b.length; i++) {
            uint8 c = uint8(b[i]);

            // Check if the character is 0-9
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            } else if (c >= 65 && c <= 70) {// Check if the character is A-F
                result = result * 16 + (c - 55);
            } else if (c >= 97 && c <= 102) {// Check if the character is a-f
                result = result * 16 + (c - 87);
            } else {
                revert("Invalid character: not a number");
            }
        }

        return result;
    }

    function getTimeDifference(uint256 timestamp1, uint256 timestamp2) public pure returns (uint256) {
        require(timestamp1 <= timestamp2, "Timestamp1 should be earlier than or equal to Timestamp2.");

        uint256 difference = timestamp2 - timestamp1;
        return difference; // Difference in seconds
    }
}