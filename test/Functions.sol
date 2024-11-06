// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";

contract Functions is Test{
    function getXToken(string calldata _xToken) public returns (XToken) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = "--rpc-url";
        inputs[3] = vm.envString("SEPOLIA_HTTP_RPC_URL"); // specify the RPC URL here
        inputs[4] = _xToken;
        inputs[5] = "balanceOf(address)";
        inputs[6] = "0xb04d6a4949fa623629e0ED6bd4Ecb78A8C847693";
        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

         // Decode the result to get the contract address
         address contractAddress = abi.decode(result, (address));

         return XToken(contractAddress);
    }

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
}
