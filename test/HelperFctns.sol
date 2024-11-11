// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";

contract HelperFctns is Test{
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
            if (charCode >= 48 && charCode <= 57) {
                result = result * 16 + (charCode - 48);
            } else if (charCode >= 65 && charCode <= 70) {
                result = result * 16 + (charCode - 55);
            } else if (charCode >= 97 && charCode <= 102) {
                result = result * 16 + (charCode - 87);
            }
        }
        return result;
    }

    function bytes32ToString(bytes32 _data) external pure returns (string memory) {
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
}