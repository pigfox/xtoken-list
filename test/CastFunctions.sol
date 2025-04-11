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
    string public rpcUrl;
    string public walletAddr;
    string public privateKey;

    constructor() {
        conversionsTest = new ConversionsTest();
        rpcUrl = vm.envString("SEPOLIA_HTTP_RPC_URL");
        walletAddr = vm.toString(vm.envAddress("WALLET_ADDRESS"));
        privateKey = vm.envString("WALLET_PRIVATE_KEY");
    }

    function addressBalance(address _contractAddress) public view returns (uint256) {
        return _contractAddress.balance;
    }

    function getTokenBalanceOf(address _holderAddress, address _tokenAddress) public view returns (uint256) {
        PigfoxToken token = PigfoxToken(_tokenAddress);
        return token.balanceOf(_holderAddress);
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

        string memory result = string(abi.encodePacked(string(castResult)));

        bytes memory status = result.parseRaw(".status");
        uint256[] memory values = abi.decode(status, (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        bytes memory transactionHash = result.parseRaw(".transactionHash");
        string memory transactionHashStr = vm.toString(transactionHash);
        return (transactionHashStr, statusInt);
    }

    function approve(address _tokenAddress, address _ownerAddress, uint256 _amount)
        public
        returns (string memory, uint256)
    {
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

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding

        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function setTokenPrice(address _dex, address _tokenAddress, uint256 _amount)
        public
        returns (string memory, uint256)
    {
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

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function getTokenPrice(string calldata _dex, string calldata _tokenAddress) public view returns (uint256) {
        IDex dex = IDex(conversionsTest.stringToAddress(_dex));
        uint256 price = dex.getTokenPrice(conversionsTest.stringToAddress(_tokenAddress));
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
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(abi.encodePacked(string(castResult)));

        uint256[] memory values = abi.decode(result.parseRaw(".status"), (uint256[]));
        uint256 statusInt = values[0];
        statusInt = statusInt == 0 ? 0 : statusInt >> (256 - 8); // Right shift to remove padding
        string memory txHash = vm.toString(result.parseRaw(".transactionHash"));
        return (txHash, statusInt);
    }

    function setProfitAddress(
        address _profitAddress,
        address _contractAddress,
        address _walletAddress,
        uint256 _privateKey
    ) external returns (string memory, uint256) {
        require(_profitAddress != address(0), "Invalid profit address");
        require(_contractAddress != address(0), "Invalid contract address");
        require(_privateKey != 0, "Invalid contract private key");

        string[] memory inputs = new string[](13);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = vm.toString(_contractAddress); // target contract address
        inputs[3] = "setProfitAddress(address)"; // function signature
        inputs[4] = vm.toString(_profitAddress); // function argument
        inputs[5] = "--json";
        inputs[6] = "--rpc-url";
        inputs[7] = vm.envString("SEPOLIA_HTTP_RPC_URL"); // or use _rpc if passed in
        inputs[8] = "--from";
        inputs[9] = vm.toString(_walletAddress);
        inputs[10] = "--private-key";
        inputs[11] = vm.toString(_privateKey);
        inputs[12] = "--legacy";

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        string memory result = string(castResult);

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
        inputs[3] = "getProfitAddress()"; // function signature
        inputs[4] = "--rpc-url";
        inputs[5] = vm.envString("SEPOLIA_HTTP_RPC_URL");
        //inputs[6] = "--json";

        bytes memory castResult = vm.ffi(inputs);
        if (castResult.length == 0) {
            console.log("Error: cast call returned empty result");
            revert("Error: cast call returned empty result");
        }

        // Decode directly from ABI-encoded return value
        address returnedAddr = abi.decode(castResult, (address));
        return returnedAddr;
    }
}
