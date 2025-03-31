// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Dex} from "../src/Dex.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {PigfoxToken} from "../src/PigfoxToken.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract CastFunctions is Test {
    using stdJson for string;
    ConversionsTest public conversionsTest;
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;

    event GetTokenBalanceOfEvent(address indexed tokenAddress, address indexed holderAddress);
    event MintEvent(address indexed tokenAddress, uint256 amount);
    event SupplyTokensEvent(address indexed supplierAddress, address indexed receiverAddress, uint256 amount);
    event DepositTokensEvent(address indexed dexAddress, address indexed tokenAddress, uint256 amount);
    event ApproveEvent(address indexed tokenAddress, address indexed ownerAddress, uint256 amount);
    event BalanceEvent(address indexed contractAddress);
    event SetTokenPriceEvent(address indexed dexAddress, address indexed tokenAddress, uint256 price);
    event GetTokenPriceEvent(address indexed dexAddress, address indexed tokenAddress);
    event GetAllowanceEvent(address indexed tokenAddress, address indexed ownerAddress, address indexed spenderAddress);
    event WithdrawTokensEvent(address indexed tokenAddress, address indexed sourceAddress, address indexed destinationAddress, uint256 amount);

    constructor() {
        conversionsTest = new ConversionsTest();
    }

    function addressBalance(string calldata _contractAddress) public returns (uint256) {
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

        emit BalanceEvent(conversionsTest.stringToAddress(_contractAddress));
        return conversionsTest.stringToUint(string(result));
    }

    function getTokenBalanceOf(string calldata _dexAddress, string calldata _tokenAddress) public returns (uint256) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = _tokenAddress;
        inputs[3] = "getTokenBalanceAt(address)"; // Ensure correct function signature
        inputs[4] = _dexAddress;
        inputs[5] = "--rpc-url";
        inputs[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");

        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve balance at contract address");
        }

        uint256 balance = abi.decode(result, (uint256));

        emit GetTokenBalanceOfEvent(
            conversionsTest.stringToAddress(_tokenAddress),
            conversionsTest.stringToAddress(_dexAddress)
        );

        return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory) {
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

        string memory result = string(abi.encodePacked(string(castResult)));

        bytes memory status = result.parseRaw(".status");
        uint256[] memory values = abi.decode(status, (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory statusStr = conversionsTest.toHexString(statusInt);
        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);
        emit MintEvent(conversionsTest.stringToAddress(_tokenAddress), _amount);
        return (transactionHashStr, statusStr);
    }

    function approve(string calldata _tokenAddress, string calldata _ownerAddress, uint256 _amount) public returns (string memory, string memory) {
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _tokenAddress;
        inputs[3] = "approve(address,uint256)";
        inputs[4] = _ownerAddress;
        inputs[5] = conversionsTest.uintToString(_amount);
        inputs[6] = "--json";
        inputs[7] = "--rpc-url";
        inputs[8] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[9] = "--from";
        inputs[10] = vm.envString("WALLET_ADDRESS");
        inputs[11] = "--private-key";
        inputs[12] = vm.envString("PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);

        if (castResult.length == 0) {
            revert("Error: approve cast call returned empty result");
        }

        string memory result = string(castResult);

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);

        emit ApproveEvent(
            conversionsTest.stringToAddress(_tokenAddress),
            conversionsTest.stringToAddress(_ownerAddress),
            _amount
        );

        return (vm.toString(result.parseRaw(".transactionHash")), conversionsTest.toHexString(statusInt));
    }

    function depositTokens(string calldata _dex, string calldata _token, uint256 _amount) public returns (string memory, string memory) {
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _token;
        inputs[3] = "supplyTokenTo(address,uint256)";
        inputs[4] = _dex;
        inputs[5] = vm.toString(_amount);
        inputs[6] = "--rpc-url";
        inputs[7] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[8] = "--from";
        inputs[9] = vm.envString("WALLET_ADDRESS");
        inputs[10] = "--private-key";
        inputs[11] = vm.envString("PRIVATE_KEY");
        inputs[12] = "--json";

        bytes memory castResult = vm.ffi(inputs);

        if (castResult.length == 0) {
            revert("Error: deposit cast call returned empty result");
        }

        string memory result = string(castResult);

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);

        emit DepositTokensEvent(
            conversionsTest.stringToAddress(_dex),
            conversionsTest.stringToAddress(_token),
            _amount
        );

        return (vm.toString(result.parseRaw(".transactionHash")), conversionsTest.toHexString(statusInt));
    }

    function setTokenPrice(string calldata _dex, string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory) {
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

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);
        emit SetTokenPriceEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_tokenAddress), _amount);
        return (vm.toString(result.parseRaw(".transactionHash")), conversionsTest.toHexString(statusInt));
    }

    function getTokenPrice(string calldata _dex, string calldata _tokenAddress) public returns (uint256) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = _dex;
        inputs[3] = "getTokenPriceOf(address)";
        inputs[4] = _tokenAddress;
        inputs[5] = "--rpc-url";
        inputs[6] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        bytes memory result = vm.ffi(inputs);

        if (result.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Failed to retrieve token price");
        }

        emit GetTokenPriceEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_tokenAddress));
        return abi.decode(result, (uint256));
    }

    function getAllowance(string calldata _token, string calldata _owner, string calldata _spender) public returns (uint256) {
        string[] memory inputs = new string[](9);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = _token;
        inputs[3] = "allowance(address,address)";
        inputs[4] = _owner;
        inputs[5] = _spender;
        inputs[6] = "--json";
        inputs[7] = "--rpc-url";
        inputs[8] = vm.envString("SEPOLIA_HTTP_RPC_URL");

        bytes memory result = vm.ffi(inputs);
        if (0 == result.length) {
            revert("Error: cast call returned empty result");
        }
        emit GetAllowanceEvent(conversionsTest.stringToAddress(_token), conversionsTest.stringToAddress(_owner), conversionsTest.stringToAddress(_spender));
        return abi.decode(result, (uint256));
    }

    function withdrawTokens(string calldata _token, string calldata _owner, string memory _destination, uint256 _amount) public returns (string memory, string memory) {
        string[] memory inputs = new string[](14);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _owner;
        inputs[3] = "withdrawTokens(address,address,uint256)";
        inputs[4] = _token;
        inputs[5] = _destination;
        inputs[6] = vm.toString(_amount);
        inputs[7] = "--json";
        inputs[8] = "--rpc-url";
        inputs[9] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[10] = "--from";
        inputs[11] = vm.envString("WALLET_ADDRESS");
        inputs[12] = "--private-key";
        inputs[13] = vm.envString("PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);
        emit WithdrawTokensEvent(
            conversionsTest.stringToAddress(_token),
            conversionsTest.stringToAddress(_owner),
            conversionsTest.stringToAddress(_destination),
            _amount
        );
        return (vm.toString(result.parseRaw(".transactionHash")), conversionsTest.toHexString(statusInt));
    }
}