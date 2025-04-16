// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ConversionsTest } from "./Conversions.sol";
import { Test, console } from "../lib/forge-std/src/Test.sol";
import { PigfoxToken } from "../src/PigfoxToken.sol";
import { IDex } from "../src/IDex.sol";
import { stdJson } from "../lib/forge-std/src/StdJson.sol";

contract CastFunctions is Test {
    using stdJson for string;

    ConversionsTest public conversionsTest;
    string public rpcUrl = vm.envString("SEPOLIA_HTTP_RPC_URL");
    string public walletAddr;
    string public privateKey;

    constructor() {
        conversionsTest = new ConversionsTest();
        rpcUrl = vm.envString("SEPOLIA_HTTP_RPC_URL");
        walletAddr = vm.toString(vm.envAddress("WALLET_ADDRESS"));
        privateKey = vm.envString("WALLET_PRIVATE_KEY");
    }

    function setOwner(address _contractAddress, address _newOwner, address _currentOwner, string memory _privateKey)
        public
        returns (string memory, uint256)
    {
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "setOwner(address)";
        inputs[4] = vm.toString(_newOwner);
        inputs[5] = "--json";
        inputs[6] = "--rpc-url";
        inputs[7] = rpcUrl;
        inputs[8] = "--from";
        inputs[9] = vm.toString(_currentOwner);
        inputs[10] = "--private-key";
        inputs[11] = _privateKey;

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            return ("0x0", 0);
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values;
        string memory txHash;

        try vm.parseJson(result, ".status") returns (bytes memory statusData) {
            values = abi.decode(statusData, (uint256[]));
        } catch {
            console.log("Error: failed to parse status json");
            return ("0x0", 0);
        }

        uint256 statusInt = values.length > 0 ? values[0] : 0;
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        try vm.parseJson(result, ".transactionHash") returns (bytes memory hashData) {
            txHash = vm.toString(hashData);
        } catch {
            console.log("Error: failed to parse transactionHash json");
            return ("0x0", 0);
        }

        // Check if txHash is empty or not 66 characters (including "0x")
        if (bytes(txHash).length == 0 || bytes(txHash).length != 66) {
            console.log("Error: txHash length is invalid");
            return ("0x0", 0);
        }

        return (txHash, statusInt);
    }

    function getOwner(address _contractAddress) public returns (address) {
        string[] memory inputs = new string[](6);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "owner()";
        inputs[4] = "--rpc-url";
        inputs[5] = rpcUrl;

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            revert("Error: cast call returned empty result");
        }

        return abi.decode(castResult, (address));
    }

    function setFlashLoanAddress(address _contractAddress, address _flashLoanAddress) public returns (string memory, uint256) {
        string[] memory inputs = new string[](11);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "setFlashLoanAddress(address)";
        inputs[4] = vm.toString(_flashLoanAddress);
        inputs[5] = "--rpc-url";
        inputs[6] = rpcUrl;
        inputs[7] = "--from";
        inputs[8] = vm.envString("WALLET_ADDRESS");
        inputs[9] = "--private-key";
        inputs[10] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function getFlashLoanAddress(address _contractAddress) public returns (address) {
        string[] memory inputs = new string[](6);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "flashLoanAddress()";
        inputs[4] = "--rpc-url";
        inputs[5] = rpcUrl;

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            revert("Error: cast call returned empty result");
        }

        return abi.decode(castResult, (address));
    }

    function addressBalance(address _contractAddress) public returns (uint256) {
        string[] memory inputs = new string[](5);
        inputs[0] = "cast";
        inputs[1] = "balance";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "--rpc-url";
        inputs[4] = rpcUrl;

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            return 0;
        }

        string memory result = string(castResult);
        bytes memory clean = bytes(result);
        uint256 len = clean.length;
        while (len > 0 && (clean[len - 1] == 0x0a || clean[len - 1] == 0x0d)) {
            len--;
        }
        assembly {
            mstore(clean, len)
        }

        uint256 balance = vm.parseUint(string(clean));
        return balance;
    }

    function getTokenBalanceOf(address _holderAddress, address _tokenAddress) public returns (uint256) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = vm.toString(_tokenAddress);
        inputs[3] = "balanceOf(address)";
        inputs[4] = vm.toString(_holderAddress);
        inputs[5] = "--rpc-url";
        inputs[6] = rpcUrl;

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            return 0;
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256 balance;
        try vm.parseJson(result, ".return") returns (bytes memory balanceData) {
            balance = abi.decode(balanceData, (uint256));
        } catch {
            console.log("Error: failed to parse balance from json");
            return 0;
        }

        return balance;
    }

    function mint(address _tokenAddress, uint256 _amount) public returns (string memory, uint256) {
        // cast send "$XToken" "mint(uint256)" 100000088840000000000667 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_tokenAddress);
        inputs[3] = "mint(uint256)";
        inputs[4] = vm.toString(_amount);
        inputs[5] = "--json";
        inputs[6] = "--rpc-url";
        inputs[7] = rpcUrl;
        inputs[8] = "--from";
        inputs[9] = vm.envString("WALLET_ADDRESS");
        inputs[10] = "--private-key";
        inputs[11] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        bytes memory status = result.parseRaw(".status");
        uint256[] memory values = abi.decode(status, (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);
        return (transactionHashStr, statusInt);
    }

    function approve(address _tokenAddress, address _ownerAddress, uint256 _amount) public returns (string memory, uint256) {
        //cast send "$XToken" "approve(address,uint256)" "$Dex1" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_tokenAddress);
        inputs[3] = "approve(address,uint256)";
        inputs[4] = vm.toString(_ownerAddress);
        inputs[5] = conversionsTest.uintToString(_amount);
        inputs[6] = "--json";
        inputs[7] = "--rpc-url";
        inputs[8] = rpcUrl;
        inputs[9] = "--from";
        inputs[10] = vm.envString("WALLET_ADDRESS");
        inputs[11] = "--private-key";
        inputs[12] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);

        if (castResult.length == 0) {
            revert("Error: approve cast call returned empty result");
        }

        string memory result = string(castResult);

        // Parse the status and transaction hash
        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);

        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function depositTokens(address _dex, address _token, uint256 _amount) public returns (string memory, uint256) {
        //cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" --json
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_token);
        inputs[3] = "supplyTokenTo(address,uint256)";
        inputs[4] = vm.toString(_dex);
        inputs[5] = vm.toString(_amount);
        inputs[6] = "--rpc-url";
        inputs[7] = rpcUrl;
        inputs[8] = "--from";
        inputs[9] = vm.envString("WALLET_ADDRESS");
        inputs[10] = "--private-key";
        inputs[11] = vm.envString("WALLET_PRIVATE_KEY");
        inputs[12] = "--json";

        bytes memory castResult = vm.ffi(inputs);

        if (castResult.length == 0) {
            revert("Error: deposit cast call returned empty result");
        }

        string memory result = string(castResult);

        // Parse the status and transaction hash
        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8);
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function withdrawTokens(string calldata _token, string calldata _owner, string memory _destination, uint256 _amount)
        public
        returns (string memory, uint256)
    {
        //cast send "$Dex1" "withdrawTokens(address,address,uint256)" "$XToken" "$TrashCan" 28000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
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
        inputs[9] = rpcUrl;
        inputs[10] = "--from";
        inputs[11] = vm.envString("WALLET_ADDRESS");
        inputs[12] = "--private-key";
        inputs[13] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function setTokenPrice(address _dex, address _tokenAddress, uint256 _amount) public returns (string memory, uint256) {
        // cast send "$dex1" "setTokenPrice(address,uint256)" "$XToken" 9876 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_dex);
        inputs[3] = "setTokenPrice(address,uint256)";
        inputs[4] = vm.toString(_tokenAddress);
        inputs[5] = conversionsTest.uintToString(_amount);
        inputs[6] = "--json";
        inputs[7] = "--rpc-url";
        inputs[8] = rpcUrl;
        inputs[9] = "--from";
        inputs[10] = vm.envString("WALLET_ADDRESS");
        inputs[11] = "--private-key";
        inputs[12] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function getTokenPrice(string memory _dex, string memory _tokenAddress) public returns (uint256) {
        address dexAddress = conversionsTest.stringToAddress(_dex);
        address tokenAddress = conversionsTest.stringToAddress(_tokenAddress);

        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = vm.toString(dexAddress);
        inputs[3] = "getTokenPrice(address)";
        inputs[4] = vm.toString(tokenAddress);
        inputs[5] = "--rpc-url";
        inputs[6] = rpcUrl;

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            return 0;
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256 price;
        try vm.parseJson(result, ".return") returns (bytes memory priceData) {
            price = abi.decode(priceData, (uint256));
        } catch {
            console.log("Error: failed to parse price from json");
            return 0;
        }

        return price;
    }

    function fundEth(address _to, uint256 _amount) public returns (string memory, uint256) {
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_to);
        inputs[3] = "--value";
        inputs[4] = vm.toString(_amount);
        inputs[5] = "--rpc-url";
        inputs[6] = rpcUrl;
        inputs[7] = "--from";
        inputs[8] = walletAddr;
        inputs[9] = "--private-key";
        inputs[10] = privateKey;
        inputs[11] = "--json";

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function getProfitAddress(address _contractAddress) public returns (address) {
        string[] memory inputs = new string[](7);
        inputs[0] = "cast";
        inputs[1] = "call";
        inputs[2] = vm.toString(_contractAddress); // target contract
        inputs[3] = "profitAddress()"; // function signature
        inputs[4] = "--rpc-url";
        inputs[5] = rpcUrl;
        inputs[6] = "--json";

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        // Decode directly from ABI-encoded return value
        return abi.decode(castResult, (address));
    }

    function setProfitAddress(address _profitAddress, address _contractAddress, address _walletAddress, string memory _privateKey)
        external
        returns (string memory, uint256)
    {
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_contractAddress);
        inputs[3] = "setProfitAddress(address)";
        inputs[4] = vm.toString(_profitAddress);
        inputs[5] = "--json";
        inputs[6] = "--rpc-url";
        inputs[7] = rpcUrl;
        inputs[8] = "--from";
        inputs[9] = vm.toString(_walletAddress);
        inputs[10] = "--private-key";
        inputs[11] = _privateKey;

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            return ("0x0", 0);
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values;
        string memory txHash;

        try vm.parseJson(result, ".status") returns (bytes memory statusData) {
            values = abi.decode(statusData, (uint256[]));
        } catch {
            console.log("Error: failed to parse status json");
            return ("0x0", 0);
        }

        uint256 statusInt = values.length > 0 ? values[0] : 0;
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        try vm.parseJson(result, ".transactionHash") returns (bytes memory hashData) {
            txHash = vm.toString(hashData);
        } catch {
            console.log("Error: failed to parse transactionHash json");
            return ("0x0", 0);
        }

        // Check if txHash is empty or not 66 characters (including "0x")
        if (bytes(txHash).length == 0 || bytes(txHash).length != 66) {
            console.log("Error: txHash length is invalid");
            return ("0x0", 0);
        }

        return (txHash, statusInt);
    }
}
