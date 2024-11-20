// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Dex} from "../src/Dex.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
//import {TransactionReceipt} from "../src/TransactionReceipt.sol";
import {XToken} from "../src/XToken.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract CastFunctionsTest is Test{
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
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;

    event GetTokenBalanceOfEvent(address indexed tokenAddress, address indexed holderAddress);
    event MintEvent(address indexed tokenAddress, uint256 amount);
    event SupplyTokensEvent(address indexed supplierAddress, address indexed receiverAddress, uint256 amount);
    event ApproveEvent(address indexed supplierAddress, address indexed receiverAddress, uint256 amount);
    event BalanceEvent(address indexed contractAddress);
    event SetTokenPriceEvent(address indexed dexAddress, address indexed tokenAddress, uint256 price);
    event GetTokenPriceEvent(address indexed dexAddress, address indexed tokenAddress);

    constructor() {
        conversionsTest = new ConversionsTest();
    }

    function addressBalance(string calldata _contractAddress) public returns (uint256) {
        /*
        cast balance 0xb04d6a4949fa623629e0ED6bd4Ecb78A8C847693 --rpc-url https://ethereum-sepolia-rpc.publicnode.com
        5343635260568317891
        */
        emit BalanceEvent(conversionsTest.stringToAddress(_contractAddress));
        string[] memory inputs = new string[](5);
        inputs[0] = "cast";
        inputs[1] = "balance";
        inputs[2] = _contractAddress;
        inputs[3] = "--rpc-url";
        inputs[4] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve wallet balance");
        }

        return conversionsTest.stringToUint(string(result));
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
        // cast send "$XToken" "approve(address,uint256)" "$dex1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        uint256 amount = type(uint256).max;
        emit ApproveEvent(conversionsTest.stringToAddress(_tokenAddress), conversionsTest.stringToAddress(_spenderAddress), amount);
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _tokenAddress;
        inputs[3] = "approve(address,uint256)";
        inputs[4] = _spenderAddress;
        inputs[5] =  conversionsTest.uintToString(amount);
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

    function setTokenPrice(string calldata _dex, string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory){
        // cast send "$dex1" "setTokenPrice(address,uint256)" "$XToken" 9876 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        emit SetTokenPriceEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_tokenAddress), _amount);
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _dex;
        inputs[3] = "setTokenPrice(address,uint256)";
        inputs[4] = _tokenAddress;
        inputs[5] = conversionsTest.uintToString(_amount);
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

    function getTokenPrice(string calldata _dex, string calldata _tokenAddress) public returns (uint256) {
        // cast call 0xeb442627f7a67a1735F06C254B693FF279BF27E7 getPrice(address) 0xBc35bD49d5de2929522E5Cc3F40460D74d24c24C --rpc-url https://ethereum-sepolia-rpc.publicnode.com
        //0x0000000000000000000000000000000000000000000000000000000000000078
        emit GetTokenPriceEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_tokenAddress));
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = _dex;
        inputs[3] = "getPrice(address)";
        inputs[4] = _tokenAddress;
        inputs[5] = "--rpc-url";
        inputs[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve token price");
        }

        return abi.decode(result, (uint256));
    }

    function emptyDex(string calldata _dex, string calldata _tokenAddress, string calldata _receiverAddress) public returns (string memory, string memory){
        // cast call "$XToken" "balanceOf(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url"
        require(bytes(_receiverAddress).length == 42, "Error: Invalid receiver address");
        require(bytes(_tokenAddress).length == 42, "Error: Invalid token address");
        require(bytes(_dex).length == 42, "Error: Invalid dex address");

        // Step 1: Approve the transfer of tokens if not already approved
        (string memory txHash, string memory statusStr) = approve(_tokenAddress, _dex);
        require(keccak256(abi.encodePacked(expectedStatusOk)) == keccak256(abi.encodePacked(statusStr)), "statusStr is not OK");
        require(expectedTxHashLength == bytes(txHash).length, "txHash length is not as expected");

        string[] memory inputsBalance = new string[](7);
        inputsBalance[0] = "cast";
        inputsBalance[1] = "call";
        inputsBalance[2] = _tokenAddress;
        inputsBalance[3] = "balanceOf(address)";
        inputsBalance[4] = _dex;
        inputsBalance[5] = "--rpc-url";
        inputsBalance[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");

        // Call `cast call` to get the balance
        bytes memory balanceResult = vm.ffi(inputsBalance);
        if (0 == balanceResult.length) {
            console.log("Error: cast call for balance returned empty result");
            revert("Error: cast call for balance returned empty result");
        }

        uint256 balance = abi.decode(balanceResult, (uint256));
        payable(conversionsTest.stringToAddress(_receiverAddress)).transfer(address(this).balance);

        // Dynamically build the inputs for the `cast send` command
        string[] memory inputsSend = new string[](13);
        inputsSend[0] = "cast";
        inputsSend[1] = "send";
        inputsSend[2] = _tokenAddress;
        inputsSend[3] = "transfer(address,uint256)";
        inputsSend[4] = _receiverAddress;
        inputsSend[5] = conversionsTest.uintToString(balance);
        inputsSend[6] = "--json";
        inputsSend[7] = "--rpc-url";
        inputsSend[8] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputsSend[9] = "--from";
        inputsSend[10] = vm.envString("WALLET_ADDRESS");
        inputsSend[11] = "--private-key";
        inputsSend[12] = vm.envString("PRIVATE_KEY");

        // Call `cast send` to transfer the tokens
        bytes memory sendResult = vm.ffi(inputsSend);
        if (0 == sendResult.length) {
            console.log("Error: cast send returned empty result");
            revert("Error: cast send returned empty result");
        }

        string memory sendJson = string(sendResult);

        // Parse the results
        bytes memory statusBytes = sendJson.parseRaw(".status");
        uint256[] memory statusValues = abi.decode(statusBytes, (uint256[]));
        uint256 statusInt = statusValues[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        statusStr = conversionsTest.toHexString(statusInt);

        bytes memory transactionHashBytes = sendJson.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHashBytes);
        require(keccak256(abi.encodePacked(expectedStatusOk)) == keccak256(abi.encodePacked(statusStr)), "statusStr is not OK");
        require(expectedTxHashLength == bytes(transactionHashStr).length, "txHash length is not as expected");

        console.log("Approval statusStr3: ", statusStr);
        console.log("Approval transaction hash3: ", txHash);

        return (transactionHashStr, statusStr);
    }

}
