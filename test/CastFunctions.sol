// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {PigfoxToken} from "../src/PigfoxToken.sol";
import {IDex} from "../src/IDex.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract CastFunctions is Test {
    using stdJson for string;
    ConversionsTest public conversionsTest;
    string public rpcUrl;
    string public walletAddr;
    string public privateKey;

    constructor() {
        conversionsTest = new ConversionsTest();
        rpcUrl = vm.envString("SEPOLIA_HTTP_RPC_URL");
        walletAddr = vm.toString(vm.envAddress("WALLET_ADDRESS"));
        privateKey = vm.envString("WALLET_PRIVATE_KEY");
    }

    function addressBalance(string calldata _contractAddress) public returns (uint256) {
        address addr = conversionsTest.stringToAddress(_contractAddress);
        uint256 balance = addr.balance;
        return balance;
    }

    function getTokenBalanceOf(string calldata _holderAddress, string calldata _tokenAddress) public returns (uint256) {
        PigfoxToken token = PigfoxToken(conversionsTest.stringToAddress(_tokenAddress));
        address holder = conversionsTest.stringToAddress(_holderAddress);
        uint256 balance = token.balanceOf(holder);
        return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory){
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
        inputs[11] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(
            abi.encodePacked(string(castResult))
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

    function approve(string calldata _tokenAddress, string calldata _ownerAddress, uint256 _amount) public returns (string memory, string memory){
        //cast send "$XToken" "approve(address,uint256)" "$Dex1" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
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
        return (txHash, conversionsTest.toHexString(statusInt));
    }

    function depositTokens(string calldata _dex, string calldata _token, uint256 _amount) public returns (string memory, string memory){
        //cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" --json
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
        return (txHash, conversionsTest.toHexString(statusInt));
    }

    function withdrawTokens(string calldata _token, string calldata _owner, string memory _destination, uint256 _amount) public returns (string memory, string memory){
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
        inputs[9] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        inputs[10] = "--from";
        inputs[11] = vm.envString("WALLET_ADDRESS");
        inputs[12] = "--private-key";
        inputs[13] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(
            abi.encodePacked(string(castResult))
        );

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return(txHash, conversionsTest.toHexString(statusInt));
    }

    function setTokenPrice(string calldata _dex, string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory){
        // cast send "$dex1" "setTokenPrice(address,uint256)" "$XToken" 9876 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
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
        inputs[12] = vm.envString("WALLET_PRIVATE_KEY");

        bytes memory castResult = vm.ffi(inputs);
        if (0 == castResult.length) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(
            abi.encodePacked(string(castResult))
        );

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return(txHash, conversionsTest.toHexString(statusInt));
    }

    function getTokenPrice(string calldata _dex, string calldata _tokenAddress) public view returns (uint256) {
        IDex dex = IDex(conversionsTest.stringToAddress(_dex));
        uint256 price = dex.getTokenPrice(conversionsTest.stringToAddress(_tokenAddress));
        return price;
    }

    function fundEth(string calldata _to, uint256 _amount) public returns (string memory, string memory) {
        string[] memory inputs = new string[](12);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = _to;
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
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(
            abi.encodePacked(string(castResult))
        );

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return(txHash, conversionsTest.toHexString(statusInt));
    }

    function setProfitAddress(address _profitAddress, address _contractAddress, uint256 _privateKey) external {
        require(_profitAddress != address(0), "Invalid profit address");
        require(_contractAddress != address(0), "Invalid contract address");
        require(_privateKey != 0, "Invalid contract private key");
    }
}

