// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {HelperFctns} from "./HelperFctns.sol";
import {Router} from "../src/Router.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {XToken} from "../src/XToken.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {TransactionReceipt} from "./TransactionReceipt.sol";

contract Functions is Test{
    HelperFctns public helperFctns;
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

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory){
        console.log("Minting ", _amount, " tokens");
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
        //console.log("Cast result",string(result));
        //"status":"0x1"
        //"transactionHash":"0x1ae6af137a7e528c7ef3e990176df3b2b4d3a15fc6d205cabdfc49a6b93f13a2",
        if (0 == result.length) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve contract address");
        }

        console.log("Result: ", string(result));

        // Parse the status field using jq
        string[] memory jqStatusCmd = new string[](3);
        jqStatusCmd[0] = "jq";
        jqStatusCmd[1] = "-r";
        jqStatusCmd[2] = ".status";

        string[] memory jqTxHashCmd = new string[](3);
        jqTxHashCmd[0] = "jq";
        jqTxHashCmd[1] = "-r";
        jqTxHashCmd[2] = ".transactionHash";

        // Use ffi to directly parse status
        bytes memory statusBytes = vm.ffi(jqStatusCmd);
        console.log("statusBytes");
        console.logBytes(statusBytes);
        string memory status = string(statusBytes);

        // Use ffi to directly parse transactionHash
        bytes memory txHashBytes = vm.ffi(jqTxHashCmd);
        console.log("txHashBytes");
        console.logBytes(txHashBytes);
        string memory transactionHash = string(txHashBytes);

        // Log the status and transactionHash as strings
        console.log("Transaction Status: ", status);
        console.log("Transaction Hash: ", transactionHash);
/*
        bytes memory data = vm.parseJson(string(result));
        //console.log("Log Bytes");
        //console.logBytes(data);

        console.log("data[\"transactionHash\"]");
        console.logBytes1(data["transactionHash"]);

        TransactionReceipt memory transactionReceipt;
        // Assuming data["transactionHash"] is a string (hex representation) and needs to be converted to bytes32
        string memory txHashString = data["transactionHash"];  // Treat the hash as a string
        bytes32 txHash = helperFctns.stringFromHex(txHashString);  // Convert the string to bytes32 using a helper function
        string memory txHashStringConverted = helperFctns.bytes32ToString(txHash);
        transactionReceipt.transactionHash = txHashStringConverted;

        console.log("transactionReceipt.transactionHash:", transactionReceipt.transactionHash);
*/


        //transactionReceipt.status = helperFctns.stringFromHex(data["status"]);
        //console.log("transactionReceipt.status", transactionReceipt.status);
        //return (helperFctns.bytes32ToString(transactionReceipt.transactionHash), string(transactionReceipt.status));
        return("","");
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
