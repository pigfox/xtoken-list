// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";
import {HelperFctns} from "./HelperFctns.sol";

contract Functions is Test{
    HelperFctns public helperFctns;
    function getXTokenBalanceOf(string calldata _tokenAddress, string calldata _holderAddress) public returns (uint256) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = "--rpc-url";
        inputs[3] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[4] = _tokenAddress;
        inputs[5] = "balanceOf(address)";
        inputs[6] = _holderAddress;
        bytes memory result = vm.ffi(inputs);
        console.logBytes(result);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

         uint256 balance = abi.decode(result, (uint256));
         return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (address, bool){
        //mirror this call in function cast send 0xBc35bD49d5de2929522E5Cc3F40460D74d24c24C mint(uint256) 100000088840000000000666 --rpc-url https://ethereum-sepolia-rpc.publicnode.com --from 0xb04d6a4949fa623629e0ED6bd4Ecb78A8C847693 --private-key de012f23692636afc7c476519954c4e7da7c50f772ab3f86faf3594266d6ad7f
        string[] memory inputs = new string[](11);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = "--rpc-url";
        inputs[3] = vm.envString("SEPOLIA_HTTP_RPC_URL"); // specify the RPC URL here
        inputs[4] = _tokenAddress;
        inputs[5] = "mint(uint256)";
        inputs[6] = vm.toString(_amount);
        inputs[7] = "--from";
        inputs[8] = vm.envString("WALLET_ADDRESS");
        inputs[9] = "--private-key";
        inputs[10] = vm.envString("PRIVATE_KEY");
        bytes memory result = vm.ffi(inputs);
        console.logBytes(result);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        (bytes32 txHash, bool success) = abi.decode(result, (bytes32, bool));
        address transactionHash = address(uint160(uint256(txHash))); // Convert txHash to an address type
        return (transactionHash, success);
    }
}
