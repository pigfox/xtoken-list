// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Dex} from "../src/Dex.sol";
import {PigfoxToken} from "../src/PigfoxToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";
import {Wallet} from "../src/Wallet.sol";

contract ArbitrageTest is Test {
    //address public pigfoxTokenAddress;
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
        //address pigfoxTokenAddress = conversionsTest.stringToAddress(pigfoxTokenAddressStr);

        dex1AddressStr = vm.envString("DEX1");
        address dex1Address = conversionsTest.stringToAddress(dex1AddressStr);

        dex2AddressStr = vm.envString("DEX2");
        address dex2Address = conversionsTest.stringToAddress(dex2AddressStr);

        vm.startPrank(walletAddress);
        arbitrage = Arbitrage(arbitrageAddress);
        assertEq(address(arbitrage), arbitrageAddress);
        arbitrage.addAccessor(walletAddress);
        arbitrage.setOwner(walletAddress);
        assertEq(arbitrage.getOwner(), walletAddress);
        require(arbitrage.accessors(walletAddress), "Accessor not added");

        dex1 = Dex(payable(dex1Address));
        dex2 = Dex(payable(dex2Address));
        vault = Vault(payable(vm.envAddress("VAULT")));

        castFunctionsTest.clearDexBalances(dex1AddressStr, pigfoxTokenAddressStr, vm.envString("TRASH_CAN"), maxAllowance);
        uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(dex1AddressStr, pigfoxTokenAddressStr);
        assertEq(dex1TokenBalance, 0);

        castFunctionsTest.clearDexBalances(dex2AddressStr, pigfoxTokenAddressStr, vm.envString("TRASH_CAN"), maxAllowance);
        uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(dex2AddressStr, pigfoxTokenAddressStr);
        assertEq(dex2TokenBalance, 0);

        (string memory txHash, string memory status) = castFunctionsTest.setTokenPrice(dex1AddressStr, pigfoxTokenAddressStr, initialDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(dex2AddressStr, pigfoxTokenAddressStr, initialDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(dex1AddressStr, pigfoxTokenAddressStr);
        assertEq(dex1TokenPrice, initialDex1TokenPrice);

        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(dex2AddressStr, pigfoxTokenAddressStr);
        assertEq(dex2TokenPrice, initialDex2TokenPrice);

        (txHash, status) = castFunctionsTest.mint(pigfoxTokenAddressStr, maxPigfoxTokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.depositTokens(dex1AddressStr, pigfoxTokenAddressStr,initialDex1TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(dex1AddressStr, pigfoxTokenAddressStr);
        assertEq(dex1TokenBalance, initialDex1TokenSupply);

        (txHash, status) = castFunctionsTest.depositTokens(dex2AddressStr, pigfoxTokenAddressStr,initialDex2TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(dex2AddressStr, pigfoxTokenAddressStr);
        assertEq(dex2TokenBalance, initialDex2TokenSupply);

        (txHash, status) = castFunctionsTest.approve(pigfoxTokenAddressStr, dex1AddressStr, maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1Allowance = castFunctionsTest.getAllowance(pigfoxTokenAddressStr, walletAddressStr, dex1AddressStr);
        assertEq(dex1Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(pigfoxTokenAddressStr, dex2AddressStr, maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex2Allowance = castFunctionsTest.getAllowance(pigfoxTokenAddressStr, walletAddressStr, dex2AddressStr);
        assertEq(dex2Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(pigfoxTokenAddressStr, arbitrageAddressStr, maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 arbitrageAllowance = castFunctionsTest.getAllowance(pigfoxTokenAddressStr, walletAddressStr, arbitrageAddressStr);
        assertEq(arbitrageAllowance, maxAllowance);

        vm.stopPrank();
        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(dex1AddressStr, pigfoxTokenAddressStr);
        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(dex2AddressStr, pigfoxTokenAddressStr);

        console.log("dex1TokenPrice", dex1TokenPrice);
        console.log("dex2TokenPrice", dex2TokenPrice);

        uint256 timeStamp = block.timestamp + 300;
        console.log("Time Stamp:", timeStamp);
        if (dex1TokenPrice == dex2TokenPrice) {
            revert("Prices are equal");
        }
        console.log("Function Test ExecuteArbitrage 2");
        /*
        if (dex1TokenPrice < dex2TokenPrice) {
            console.log("Buy from Dex1 sell to Dex2");
            uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(dex1AddressStr, pigfoxTokenAddressStr);
            arbitrage.run(address(pigfoxToken), address(dex1), address(dex2), dex1TokenBalance, timeStamp);
        }

        if (dex2TokenPrice < dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(dex2AddressStr, pigfoxTokenAddressStr);
            arbitrage.run(address(pigfoxToken), address(dex2), address(dex1), dex2TokenBalance, timeStamp);
        }
*/
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
