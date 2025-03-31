// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/PigfoxToken.sol";
import "../src/IDex.sol";
import "../src/Arbitrage.sol";
import "../src/Vault.sol";
import "./CastFunctions.sol";

contract ArbitrageTest is Test {
    CastFunctions public castFunctions;
    address public walletAddr;

    // Environment variables as constants
    string constant SEPOLIA_RPC_URL = "SEPOLIA_HTTP_RPC_URL";
    string constant WALLET_ADDRESS = "WALLET_ADDRESS";
    string constant PIGFOX_TOKEN = "PIGFOX_TOKEN";
    string constant DEX1 = "DEX1";
    string constant DEX2 = "DEX2";
    string constant ARBITRAGE = "ARBITRAGE";
    string constant VAULT = "VAULT";

    // Constants for token and ETH amounts
    uint256 constant DECIMALS = 10**18;
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS;
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;
    uint256 constant VAULT_ETH_FUNDING = 10 * DECIMALS;
    uint256 constant ARBITRAGE_ETH_FUNDING = 1 * DECIMALS;
    uint256 constant DEX_ETH_FUNDING = 1 * DECIMALS;
    uint256 constant WALLET_ETH_BUFFER = 2 * DECIMALS;

    // Constants for DEX prices
    uint256 constant DEX1_PRICE = 120;
    uint256 constant DEX2_PRICE = 80;

    // Constant for deadline extension
    uint256 constant DEADLINE_EXTENSION = 1000;

    // Contract addresses as strings for cast calls
    string pigfoxTokenAddr;
    string dex1Addr;
    string dex2Addr;
    string arbitrageAddr;
    string vaultAddr;

    function setUp() public {
        castFunctions = new CastFunctions();

        walletAddr = vm.envAddress(WALLET_ADDRESS);
        pigfoxTokenAddr = vm.toString(vm.envAddress(PIGFOX_TOKEN));
        dex1Addr = vm.toString(vm.envAddress(DEX1));
        dex2Addr = vm.toString(vm.envAddress(DEX2));
        arbitrageAddr = vm.toString(vm.envAddress(ARBITRAGE));
        vaultAddr = vm.toString(vm.envAddress(VAULT));

        console.log("Wallet Address:", walletAddr);
        console.log("PigfoxToken Address:", pigfoxTokenAddr);
        console.log("DEX1 Address:", dex1Addr);
        console.log("DEX2 Address:", dex2Addr);
        console.log("Arbitrage Address:", arbitrageAddr);
        console.log("Vault Address:", vaultAddr);

        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(vm.toString(walletAddr), pigfoxTokenAddr);
        console.log("Wallet PFX Balance:");
        console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            console.log("Minting 100 PFX to wallet...");
            (string memory txHash, string memory status) = castFunctions.mint(pigfoxTokenAddr, MIN_WALLET_PFX_BALANCE);
            require(keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("0x1")), "Mint failed");
            console.log("Minted 100 PFX, Tx Hash:", txHash);
        }

        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            (, string memory approveStatus1) = castFunctions.approve(pigfoxTokenAddr, dex1Addr, DEX_PFX_DEPOSIT); // Ignore tx hash
            require(keccak256(abi.encodePacked(approveStatus1)) == keccak256(abi.encodePacked("0x1")), "Approve DEX1 failed");
            (string memory depositTx1, string memory depositStatus1) = castFunctions.depositTokens(dex1Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            require(keccak256(abi.encodePacked(depositStatus1)) == keccak256(abi.encodePacked("0x1")), "Deposit to DEX1 failed");
            console.log("Deposited 50 PFX to DEX1, Tx Hash:", depositTx1);
        }

        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            (, string memory approveStatus2) = castFunctions.approve(pigfoxTokenAddr, dex2Addr, DEX_PFX_DEPOSIT); // Ignore tx hash
            require(keccak256(abi.encodePacked(approveStatus2)) == keccak256(abi.encodePacked("0x1")), "Approve DEX2 failed");
            (string memory depositTx2, string memory depositStatus2) = castFunctions.depositTokens(dex2Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            require(keccak256(abi.encodePacked(depositStatus2)) == keccak256(abi.encodePacked("0x1")), "Deposit to DEX2 failed");
            console.log("Deposited 50 PFX to DEX2, Tx Hash:", depositTx2);
        }

        uint256 walletEthBalance = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        console.log("Wallet ETH Balance:");
        console2.logUint(walletEthBalance);
        if (walletEthBalance < requiredEth) {
            console.log("Insufficient ETH in wallet. Please fund wallet with at least 15 ETH manually.");
            return;
        }

        uint256 vaultEthBalance = castFunctions.addressBalance(vaultAddr);
        console.log("Vault ETH Balance:");
        console2.logUint(vaultEthBalance);
        if (vaultEthBalance < VAULT_ETH_FUNDING) {
            string[] memory inputs = new string[](12);
            inputs[0] = "cast";
            inputs[1] = "send";
            inputs[2] = vaultAddr;
            inputs[3] = "depositETH()";
            inputs[4] = "--value";
            inputs[5] = vm.toString(VAULT_ETH_FUNDING);
            inputs[6] = "--rpc-url";
            inputs[7] = vm.envString(SEPOLIA_RPC_URL);
            inputs[8] = "--from";
            inputs[9] = vm.toString(walletAddr);
            inputs[10] = "--private-key";
            inputs[11] = vm.envString("PRIVATE_KEY");
            bytes memory result = vm.ffi(inputs);
            require(result.length > 0, "Failed to fund Vault with ETH");
            console.log("Funded Vault with 10 ETH");
        }

        uint256 arbitrageEthBalance = castFunctions.addressBalance(arbitrageAddr);
        if (arbitrageEthBalance < ARBITRAGE_ETH_FUNDING) {
            string[] memory inputs = new string[](11);
            inputs[0] = "cast";
            inputs[1] = "send";
            inputs[2] = arbitrageAddr;
            inputs[3] = "--value";
            inputs[4] = vm.toString(ARBITRAGE_ETH_FUNDING);
            inputs[5] = "--rpc-url";
            inputs[6] = vm.envString(SEPOLIA_RPC_URL);
            inputs[7] = "--from";
            inputs[8] = vm.toString(walletAddr);
            inputs[9] = "--private-key";
            inputs[10] = vm.envString("PRIVATE_KEY");
            bytes memory result = vm.ffi(inputs);
            require(result.length > 0, "Failed to fund Arbitrage with ETH");
            console.log("Funded Arbitrage with 1 ETH");
        }

        uint256 dex1EthBalance = castFunctions.addressBalance(dex1Addr);
        if (dex1EthBalance < DEX_ETH_FUNDING) {
            string[] memory inputs = new string[](11);
            inputs[0] = "cast";
            inputs[1] = "send";
            inputs[2] = dex1Addr;
            inputs[3] = "--value";
            inputs[4] = vm.toString(DEX_ETH_FUNDING);
            inputs[5] = "--rpc-url";
            inputs[6] = vm.envString(SEPOLIA_RPC_URL);
            inputs[7] = "--from";
            inputs[8] = vm.toString(walletAddr);
            inputs[9] = "--private-key";
            inputs[10] = vm.envString("PRIVATE_KEY");
            bytes memory result = vm.ffi(inputs);
            require(result.length > 0, "Failed to fund DEX1 with ETH");
            console.log("Funded DEX1 with 1 ETH");
        }

        uint256 dex2EthBalance = castFunctions.addressBalance(dex2Addr);
        if (dex2EthBalance < DEX_ETH_FUNDING) {
            string[] memory inputs = new string[](11);
            inputs[0] = "cast";
            inputs[1] = "send";
            inputs[2] = dex2Addr;
            inputs[3] = "--value";
            inputs[4] = vm.toString(DEX_ETH_FUNDING);
            inputs[5] = "--rpc-url";
            inputs[6] = vm.envString(SEPOLIA_RPC_URL);
            inputs[7] = "--from";
            inputs[8] = vm.toString(walletAddr);
            inputs[9] = "--private-key";
            inputs[10] = vm.envString("PRIVATE_KEY");
            bytes memory result = vm.ffi(inputs);
            require(result.length > 0, "Failed to fund DEX2 with ETH");
            console.log("Funded DEX2 with 1 ETH");
        }

        uint256 dex1Price = castFunctions.getTokenPrice(dex1Addr, pigfoxTokenAddr);
        if (dex1Price != DEX1_PRICE) {
            (string memory txHash, string memory status) = castFunctions.setTokenPrice(dex1Addr, pigfoxTokenAddr, DEX1_PRICE);
            require(keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("0x1")), "Set DEX1 price failed");
            console.log("Set DEX1 price to 120 wei/PFX, Tx Hash:", txHash);
        }

        uint256 dex2Price = castFunctions.getTokenPrice(dex2Addr, pigfoxTokenAddr);
        if (dex2Price != DEX2_PRICE) {
            (string memory txHash, string memory status) = castFunctions.setTokenPrice(dex2Addr, pigfoxTokenAddr, DEX2_PRICE);
            require(keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked("0x1")), "Set DEX2 price failed");
            console.log("Set DEX2 price to 80 wei/PFX, Tx Hash:", txHash);
        }
    }

    function test_executeArbitrage() public {
        uint256 initialArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 initialWalletEth = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 initialDex1Pfx = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        uint256 initialDex2Pfx = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("Initial Arbitrage ETH:");
        console2.logUint(initialArbEth);
        console.log("Initial Wallet ETH:");
        console2.logUint(initialWalletEth);
        console.log("Initial DEX1 PFX:");
        console2.logUint(initialDex1Pfx);
        console.log("Initial DEX2 PFX:");
        console2.logUint(initialDex2Pfx);

        uint256 dex1Price = castFunctions.getTokenPrice(dex1Addr, pigfoxTokenAddr);
        uint256 dex2Price = castFunctions.getTokenPrice(dex2Addr, pigfoxTokenAddr);
        console.log("DEX1 Price (wei/PFX):");
        console2.logUint(dex1Price);
        console.log("DEX2 Price (wei/PFX):");
        console2.logUint(dex2Price);
        require(dex2Price < dex1Price, "No arbitrage opportunity");

        string[] memory inputs = new string[](15);
        inputs[0] = "cast";
        inputs[1] = "send";
        inputs[2] = arbitrageAddr;
        inputs[3] = "run(address,address,address,uint256,uint256)";
        inputs[4] = pigfoxTokenAddr;
        inputs[5] = dex2Addr;
        inputs[6] = dex1Addr;
        inputs[7] = vm.toString(TRADE_AMOUNT);
        inputs[8] = vm.toString(block.timestamp + DEADLINE_EXTENSION);
        inputs[9] = "--rpc-url";
        inputs[10] = vm.envString(SEPOLIA_RPC_URL);
        inputs[11] = "--from";
        inputs[12] = vm.toString(walletAddr);
        inputs[13] = "--private-key";
        inputs[14] = vm.envString("PRIVATE_KEY");
        bytes memory result = vm.ffi(inputs);
        require(result.length > 0, "Arbitrage execution failed");
        console.log("Arbitrage executed");

        uint256 finalArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 finalWalletEth = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 finalDex1Pfx = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        uint256 finalDex2Pfx = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("Final Arbitrage ETH:");
        console2.logUint(finalArbEth);
        console.log("Final Wallet ETH:");
        console2.logUint(finalWalletEth);
        console.log("Final DEX1 PFX:");
        console2.logUint(finalDex1Pfx);
        console.log("Final DEX2 PFX:");
        console2.logUint(finalDex2Pfx);

        uint256 profit = finalWalletEth - initialWalletEth;
        assertGt(profit, 0, "No profit made");
        console.log("Profit (ETH wei):");
        console2.logUint(profit);

        uint256 expectedDex2Pfx = initialDex2Pfx - TRADE_AMOUNT;
        uint256 expectedDex1Pfx = initialDex1Pfx + TRADE_AMOUNT;
        assertEq(finalDex2Pfx, expectedDex2Pfx, "DEX2 balance incorrect");
        assertEq(finalDex1Pfx, expectedDex1Pfx, "DEX1 balance incorrect");
    }
}