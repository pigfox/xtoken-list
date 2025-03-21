// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console, console2} from "forge-std/Test.sol"; // Ensure correct import path
import {Dex} from "../src/Dex.sol";
import {PigfoxToken} from "../src/PigfoxToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";
import {Wallet} from "../src/Wallet.sol";

contract ArbitrageTest is Test {
    string public dex1AddressStr;
    string public dex2AddressStr;
    string public pigfoxTokenAddressStr;
    Dex public dex1;
    Dex public dex2;
    CastFunctionsTest public castFunctionsTest = new CastFunctionsTest();
    ConversionsTest public conversionsTest = new ConversionsTest();
    PigfoxToken public pigfoxToken;
    Wallet public wallet;
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public initialDex1TokenSupply = 7e18;
    uint256 public initialDex2TokenSupply = 13e18;
    uint256 public maxPigfoxTokenSupply = initialDex1TokenSupply + initialDex2TokenSupply;
    uint256 public initialDex1TokenPrice = 120;
    uint256 public initialDex2TokenPrice = 80;
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;
    uint256 public maxAllowance = type(uint256).max;

    function setUp() public {
        string memory walletAddressStr = vm.envString("WALLET_ADDRESS");
        address walletAddress = conversionsTest.stringToAddress(walletAddressStr);

        string memory arbitrageAddressStr = vm.envString("ARBITRAGE");
        address arbitrageAddress = conversionsTest.stringToAddress(arbitrageAddressStr);

        pigfoxTokenAddressStr = vm.envString("PIGFOX_TOKEN");
        address pigfoxTokenAddress = conversionsTest.stringToAddress(pigfoxTokenAddressStr);

        dex1AddressStr = vm.envString("DEX1");
        address dex1Address = conversionsTest.stringToAddress(dex1AddressStr);

        dex2AddressStr = vm.envString("DEX2");
        address dex2Address = conversionsTest.stringToAddress(dex2AddressStr);

        pigfoxToken = PigfoxToken(pigfoxTokenAddress);
        wallet = Wallet(payable(walletAddress));
        dex1 = Dex(payable(dex1Address));
        dex2 = Dex(payable(dex2Address));
        vault = Vault(payable(vm.envAddress("VAULT")));
        arbitrage = Arbitrage(arbitrageAddress);

        // Verify contract deployment
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(arbitrageAddress)
        }
        console.log("Arbitrage contract code size:");
        console2.logUint(codeSize);
        require(codeSize > 0, "Arbitrage contract not deployed at specified address");

        // Attempt to call getOwner
        address ownerBefore = arbitrage.getOwner();
        console.log("Arbitrage Owner before setup:", ownerBefore);
        console.log("Wallet Address:", walletAddress);

        vm.startPrank(walletAddress);
        assertEq(address(arbitrage), arbitrageAddress);
        arbitrage.addAccessor(walletAddress);
        arbitrage.setOwner(walletAddress);
        assertEq(arbitrage.getOwner(), walletAddress);
        require(arbitrage.accessors(walletAddress), "Accessor not added");

        // Reset wallet balance
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        uint256 initialWalletBalance = pigfoxToken.balanceOf(walletAddress);
        if (initialWalletBalance > 0) {
            pigfoxToken.transfer(burnAddress, initialWalletBalance);
            console.log("Transferred initial balance to burn address:");
            console2.logUint( initialWalletBalance);
        }

        // Mint tokens to wallet
        (string memory txHash, string memory status) = castFunctionsTest.mint(pigfoxTokenAddressStr, maxPigfoxTokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        pigfoxToken.supplyTokenTo(walletAddress, maxPigfoxTokenSupply);

        uint256 walletBalance = pigfoxToken.balanceOf(walletAddress);
        console.log("Wallet Balance after mint:");
        console2.logUint(walletBalance);
        assertEq(walletBalance, maxPigfoxTokenSupply, "Minting failed");

        // Set token prices
        (txHash, status) = castFunctionsTest.setTokenPrice(dex1AddressStr, pigfoxTokenAddressStr, initialDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(dex1AddressStr, pigfoxTokenAddressStr);
        assertEq(dex1TokenPrice, initialDex1TokenPrice);

        (txHash, status) = castFunctionsTest.setTokenPrice(dex2AddressStr, pigfoxTokenAddressStr, initialDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(dex2AddressStr, pigfoxTokenAddressStr);
        assertEq(dex2TokenPrice, initialDex2TokenPrice);

        // Approve and transfer to DEX1
        pigfoxToken.approve(address(dex1), initialDex1TokenSupply);
        pigfoxToken.transfer(address(dex1), initialDex1TokenSupply);
        uint256 dex1TokenBalance = pigfoxToken.balanceOf(address(dex1));
        console.log("DEX1 Balance after transfer:");
        console2.logUint(dex1TokenBalance);
        assertEq(dex1TokenBalance, initialDex1TokenSupply, "DEX1 deposit failed");

        // Approve and transfer to DEX2
        pigfoxToken.approve(address(dex2), initialDex2TokenSupply);
        pigfoxToken.transfer(address(dex2), initialDex2TokenSupply);
        uint256 dex2TokenBalance = pigfoxToken.balanceOf(address(dex2));
        console.log("DEX2 Balance after transfer:");
        console2.logUint(dex2TokenBalance);
        assertEq(dex2TokenBalance, initialDex2TokenSupply, "DEX2 deposit failed");

        // Approve arbitrage contract
        pigfoxToken.approve(address(arbitrage), maxAllowance);
        uint256 arbitrageAllowance = pigfoxToken.allowance(walletAddress, address(arbitrage));
        assertEq(arbitrageAllowance, maxAllowance, "Arbitrage approval failed");

        vm.stopPrank();
        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage() public {
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(dex1AddressStr, pigfoxTokenAddressStr);
        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(dex2AddressStr, pigfoxTokenAddressStr);
        console.log("dex1TokenPrice:");
        console2.logUint(dex1TokenPrice);

        console.log("dex2TokenPrice:");
        console2.logUint(dex2TokenPrice);

        uint256 timeStamp = block.timestamp + 300;
        console.log("timeStamp:");
        console2.logUint(timeStamp);
        if (dex1TokenPrice == dex2TokenPrice) {
            revert("Prices are equal");
        }

        // Verify balances before execution
        uint256 dex1Balance = pigfoxToken.balanceOf(address(dex1));
        uint256 dex2Balance = pigfoxToken.balanceOf(address(dex2));
        console.log("DEX1 Balance before arbitrage:");
        console2.logUint(dex1Balance);
        console.log("DEX2 Balance before arbitrage:");
        console2.logUint(dex2Balance);
        assertEq(dex1Balance, initialDex1TokenSupply, "DEX1 balance incorrect");
        assertEq(dex2Balance, initialDex2TokenSupply, "DEX2 balance incorrect");

        // Impersonate DEX1 and approve arbitrage
        vm.startPrank(address(dex1));
        pigfoxToken.approve(address(arbitrage), type(uint256).max);
        vm.stopPrank();

        // Impersonate DEX2 and approve arbitrage
        vm.startPrank(address(dex2));
        pigfoxToken.approve(address(arbitrage), type(uint256).max);
        vm.stopPrank();

        // Execute arbitrage as wallet
        vm.startPrank(address(wallet));
        if (dex1TokenPrice < dex2TokenPrice) {
            console.log("Buy from Dex1 sell to Dex2");
            uint256 dex1TokenBalance = pigfoxToken.balanceOf(address(dex1));
            arbitrage.run(address(pigfoxToken), address(dex1), address(dex2), dex1TokenBalance, timeStamp);
        } else if (dex2TokenPrice < dex1TokenPrice) {
            console.log("Buy from Dex2 sell to Dex1");
            uint256 dex2TokenBalance = pigfoxToken.balanceOf(address(dex2));
            arbitrage.run(address(pigfoxToken), address(dex2), address(dex1), dex2TokenBalance, timeStamp);
        }
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        console.log("Gas end:");
        console2.logUint(gasEnd);

        console.log("Gas used:");
        uint256 gasUsed = gasStart - gasEnd;
        console2.logUint(gasUsed);
    }
}