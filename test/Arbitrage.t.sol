// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Dex} from "../src/Dex.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";

contract ArbitrageTest is Test {
    address public ownerAddress;
    address public xTokenAddress;
    CastFunctionsTest public castFunctionsTest;
    ConversionsTest public conversionsTest;
    XToken public xToken;
    Dex public dex1 = new Dex();
    Dex public dex2 = new Dex();
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public initialDex1TokenSupply = 7e18;
    uint256 public initialDex2TokenSupply = 13e18;
    uint256 public maxTokenSupply = initialDex1TokenSupply + initialDex2TokenSupply;
    uint256 public initialDex1TokenPrice = 120;
    uint256 public initialDex2TokenPrice = 80;
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;

    function setUp() public {
        dex1 = Dex(payable(vm.envAddress("Dex1")));
        dex2 = Dex(payable(vm.envAddress("Dex2")));

        ownerAddress = vm.envAddress("WALLET_ADDRESS");
        castFunctionsTest = new CastFunctionsTest();
        conversionsTest = new ConversionsTest();
        xTokenAddress = vm.envAddress("XToken");
        console.log("Owner Address:", ownerAddress);
        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        vault = Vault(payable(vm.envAddress("Vault")));
/*
        string memory walletAddressStr = vm.envString("WALLET_ADDRESS");
        console.log("walletAddressStr:", walletAddressStr);
        address convertedWalletAddress = conversionsTest.stringToAddress(walletAddressStr);
        console.log("convertedWalletAddress:", convertedWalletAddress);
        address walletAddress = vm.envAddress("WALLET_ADDRESS");
        console.log("walletAddress:", walletAddress);
        assertEq(convertedWalletAddress, walletAddress);

*/
        castFunctionsTest.emptyDex(vm.envString("Dex1"), vm.envString("XToken"), vm.envString("TrashCan"));
        castFunctionsTest.emptyDex(vm.envString("Dex2"), vm.envString("XToken"), vm.envString("TrashCan"));

        (string memory txHash, string memory status)  = castFunctionsTest.setTokenPrice(vm.envString("Dex1"), vm.envString("XToken"), initialDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("Dex2"), vm.envString("XToken"), initialDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex1"), vm.envString("XToken"));
        assertEq(dex1TokenPrice, initialDex1TokenPrice);

        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex2"), vm.envString("XToken"));
        assertEq(dex2TokenPrice, initialDex2TokenPrice);

        (txHash, status) = castFunctionsTest.mint(vm.envString("XToken"), maxTokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex1"), vm.envString("XToken"),vm.envString("XToken"),initialDex1TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
        assertEq(dex1TokenBalance, initialDex1TokenSupply);

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex2"), vm.envString("XToken"),vm.envString("XToken"),initialDex2TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
        assertEq(dex2TokenBalance, initialDex2TokenSupply);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex1"), vm.envString("XToken"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex2"), vm.envString("XToken"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex1"), vm.envString("XToken"));
        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex2"), vm.envString("XToken"));

        if (dex1TokenPrice == dex2TokenPrice) {
            revert("Prices are equal");
        } else if (dex1TokenPrice < dex2TokenPrice) {
            console.log("Buy from Dex1 sell to Dex2");
            uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
            arbitrage.executeArbitrage(address(xToken), address(dex1), address(dex2), dex1TokenBalance, block.timestamp);
        } else if (dex2TokenPrice < dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
            arbitrage.executeArbitrage(address(xToken), address(dex2), address(dex1), dex2TokenBalance, block.timestamp);
        }

        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used:", gasUsed);
    }
/*
    function test_setProfitAddress()public{
        vm.startPrank(ownerAddress);
        console.log("Function Test SetProfitAddress");
        address profitAddress = vm.envAddress("WALLET_ADDRESS");
        arbitrage.setProfitAddress(profitAddress);
        vm.stopPrank();
        assertEq(arbitrage.profitAddress(), profitAddress);
    }

*/

    /*
    function tearDown() public {
        vm.stopPrank(); // Ensure prank is stopped after each test
    }
    */
}
