// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Dex} from "../src/Dex.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";
import {Wallet} from "../src/Wallet.sol";

contract ArbitrageTest is Test {
    address public xTokenAddress;
    CastFunctionsTest public castFunctionsTest;
    ConversionsTest public conversionsTest;
    XToken public xToken;
    Wallet public wallet;
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
    uint256 public maxAllowance = type(uint256).max;

    function setUp() public {
        dex1 = Dex(payable(vm.envAddress("Dex1")));
        dex2 = Dex(payable(vm.envAddress("Dex2")));
        vault = Vault(payable(vm.envAddress("Vault")));

        wallet = new Wallet(vm.envAddress("WALLET_ADDRESS"));
        castFunctionsTest = new CastFunctionsTest();
        conversionsTest = new ConversionsTest();
        xTokenAddress = vm.envAddress("XToken");

        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        vm.startPrank(vm.envAddress("WALLET_ADDRESS"));
        wallet.addAccessor(vm.envAddress("Arbitrage"), vm.envAddress("Arbitrage"));
        console.logAddress(wallet.getOwner());
        console.logAddress(vm.envAddress("WALLET_ADDRESS"));
        assertEq(wallet.getOwner(), vm.envAddress("WALLET_ADDRESS"));
        console.logAddress(vm.envAddress("Arbitrage"));
        vm.stopPrank();

        //IArbitrageContract(vm.envAddress("Arbitrage")).addAccessor(address(0));


        /*
        (string memory txHash, string memory status) = castFunctionsTest.approve(vm.envString("Dex1"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 dex1Allowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Dex1"), vm.envString("Arbitrage"));
        assertEq(dex1Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex2"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 dex2Allowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Dex2"), vm.envString("Arbitrage"));
        assertEq(dex2Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Arbitrage"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 arbitrageAllowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Arbitrage"), vm.envString("Arbitrage"));
        assertEq(arbitrageAllowance, maxAllowance);
*/
/*
        castFunctionsTest.clearDexBalances(vm.envString("Dex1"), vm.envString("XToken"), vm.envString("TrashCan"), maxAllowance);
        //castFunctionsTest.emptyDex(vm.envString("Dex1"), vm.envString("WALLET_ADDRESS"), vm.envString("TrashCan"), maxAllowance);
        uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
        //assertEq(dex1TokenBalance, 0);
        dex1TokenBalance;

        castFunctionsTest.clearDexBalances(vm.envString("Dex2"), vm.envString("XToken"), vm.envString("TrashCan"), maxAllowance);
        //castFunctionsTest.emptyDex(vm.envString("Dex2"), vm.envString("WALLET_ADDRESS"), vm.envString("TrashCan"), maxAllowance);
        uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
        //assertEq(dex2TokenBalance, 0);
        dex2TokenBalance;

        (string memory txHash, string memory status) = castFunctionsTest.setTokenPrice(vm.envString("Dex1"), vm.envString("XToken"), initialDex1TokenPrice);
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

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex1"), vm.envString("XToken"),initialDex1TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
        assertEq(dex1TokenBalance, initialDex1TokenSupply);

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex2"), vm.envString("XToken"),initialDex2TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
        assertEq(dex2TokenBalance, initialDex2TokenSupply);
*/
       /*
        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex1"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 dex1Allowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Dex1"), vm.envString("Arbitrage"));
        assertEq(dex1Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex2"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 dex2Allowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Dex2"), vm.envString("Arbitrage"));
        assertEq(dex2Allowance, maxAllowance);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Arbitrage"), vm.envString("XToken"), maxAllowance);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);
        uint256 arbitrageAllowance = castFunctionsTest.getAllowance(vm.envString("XToken"), vm.envString("Arbitrage"), vm.envString("Arbitrage"));
        assertEq(arbitrageAllowance, maxAllowance);
*/
        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex1"), vm.envString("XToken"));
        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex2"), vm.envString("XToken"));

        console.log("dex1TokenPrice", dex1TokenPrice);
        console.log("dex2TokenPrice", dex2TokenPrice);

        uint256 timeStamp = block.timestamp + 300;
        console.log("Time Stamp:", timeStamp);
        if (dex1TokenPrice == dex2TokenPrice) {
            revert("Prices are equal");
        } else if (dex1TokenPrice < dex2TokenPrice) {
            console.log("Buy from Dex1 sell to Dex2");
            uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
            arbitrage.run(address(xToken), address(dex1), address(dex2), dex1TokenBalance, timeStamp);
        } else if (dex2TokenPrice < dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
            arbitrage.run(address(xToken), address(dex2), address(dex1), dex2TokenBalance, timeStamp);
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
