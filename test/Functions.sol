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

    event GetTokenBalanceOfEvent(address indexed tokenAddress, address indexed holderAddress);
    event MintEvent(address indexed tokenAddress, uint256 amount);
    event SupplyTokensEvent(address indexed supplierAddress, address indexed receiverAddress, uint256 amount);
    event ApproveEvent(address indexed supplierAddress, address indexed receiverAddress, uint256 amount);

    constructor() {
        conversionsTest = new ConversionsTest();
    }

    function walletBalance() public view returns (uint256) {
        //cast balance <WALLET_ADDRESS> --rpc-url <RPC_URL>
        return address(this).balance;
    }

    function getTokenBalanceOf(string calldata _tokenAddress, string calldata _holderAddress) public returns (uint256) {
        //cast call "$XToken" "balanceOf(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url"
        emit GetTokenBalanceOfEvent(conversionsTest.stringToAddress(_tokenAddress), conversionsTest.stringToAddress(_holderAddress));
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
        emit MintEvent(conversionsTest.stringToAddress(_tokenAddress), _amount);
        //console.log("Minting ", _amount, "tokens");
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
        string memory statusStr = conversionsTest.toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);

        return(transactionHashStr,statusStr);
    }

    function supplyTokensTo(string calldata _supplierAddress, string calldata _receiverAddress, uint256 _amount) public returns (string memory, string memory) {
        // cast send "$XToken" "supplyTokenTo(address,uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        emit SupplyTokensEvent(conversionsTest.stringToAddress(_supplierAddress), conversionsTest.stringToAddress(_receiverAddress),_amount);
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
        string memory statusStr = conversionsTest.toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);

        return(transactionHashStr,statusStr);
    }

    function approve(string calldata _tokenAddress, string calldata _spenderAddress) public returns (string memory, string memory){
        // cast send "$XToken" "approve(address,uint256)" "$Router1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string memory amount = maxAmount();
        emit ApproveEvent(conversionsTest.stringToAddress(_tokenAddress), conversionsTest.stringToAddress(_spenderAddress), conversionsTest.stringToUint(amount));
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _tokenAddress;
        inputs[3] = "approve(address,uint256)";
        inputs[4] = _spenderAddress;
        inputs[5] =  amount;
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
        string memory statusStr = conversionsTest.toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);

        return(transactionHashStr,statusStr);
    }

    function maxAmount() internal view returns(string memory){
        string memory maxUint256Str = conversionsTest.toHexString(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        return maxUint256Str;
    }
}
