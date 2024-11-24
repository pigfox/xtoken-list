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
/*
        uint256 walletBalance = castFunctionsTest.addressBalance(vm.envString("WALLET_ADDRESS"));
        console.log("walletBalanceX:", walletBalance);

        uint256 xTokenWalletBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("XToken"), vm.envString("WALLET_ADDRESS"));
        console.log("xTokenWalletBalance:", xTokenWalletBalance);
*/
        (string memory txHash, string memory status) = castFunctionsTest.mint(vm.envString("XToken"), maxTokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex1"), vm.envString("XToken"),initialDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex1"), vm.envString("XToken"));
        dex1TokenBalance;
        //assertEq(dex1TokenBalance, initialDex1TokenSupply);

        (txHash, status) = castFunctionsTest.depositTokens(vm.envString("Dex2"), vm.envString("XToken"),initialDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 dex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Dex2"), vm.envString("XToken"));
        dex2TokenBalance;
        //assertEq(dex2TokenBalance, initialDex2TokenSupply);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex1"), vm.envString("XToken"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.approve(vm.envString("Dex2"), vm.envString("XToken"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("Dex1"), vm.envString("XToken"), initialDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("Dex2"), vm.envString("XToken"), initialDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 Dex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex1"), vm.envString("XToken"));
        Dex1TokenPrice;
        //assertEq(Dex1TokenPrice, initialDex1TokenPrice);

        uint256 Dex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex2"), vm.envString("XToken"));
        Dex2TokenPrice;
        //assertEq(Dex2TokenPrice, initialDex2TokenPrice);

        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();

        uint256 dex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex1"), vm.envString("XToken"));
        uint256 dex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Dex2"), vm.envString("XToken"));

        if (dex1TokenPrice == dex2TokenPrice) {
            revert("Prices are equal");
        }
        /*
        if (Dex1TokenPrice < Dex2TokenPrice){
            console.log("Buy from Dex1 sell to Dex2");
            arbitrage.executeArbitrage(address(xToken), address(dex1), address(dex2), Dex1TokenBalance, block.timestamp);
        }
        if (Dex2TokenPrice < Dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            arbitrage.executeArbitrage(address(xToken), address(dex2), address(dex1), Dex2TokenBalance, block.timestamp);
        }
*/
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used:", gasUsed);

        /*

        arbitrage.executeArbitrage(address(xToken), address(Dex1), address(Dex2), 1 ether, block.timestamp);
        address xTokenAddress = DevOpsTools.get_most_recent_deployment("XToken", block.chainid);
        XToken xToken1 = XToken(xTokenAddress);
        console.log("DevOpsTools xTokenAddress:", xTokenAddress);

        console.log("vm.envAddress(\"XToken\"):", vm.envAddress("XToken"));
        XToken xToken2 = XToken(vm.envAddress("XToken"));//address from deployed contract on Sepolia


        vm.startPrank(ownerAddress);
        console.log("Function Test SwapTokens");
        address arbitrageOwner = arbitrage.owner();
        console.log("arbitrageOwner:",arbitrageOwner);
        assert(msg.sender == ownerAddress);
        uint256 initialVaultBalance = vault.tokenBalance(address(xToken));
        uint256 initialVaultETHBalance = vault.ethBalance();
        uint256 Dex1TokenPrice = Dex1.getTokenPrice(address(xToken));
        console.log("--Dex1 address:", address(Dex1));
        console.log("--Dex1TokenPrice:", Dex1TokenPrice);
        console.log("--Dex2 address:", address(Dex2));
        uint256 Dex2TokenPrice = Dex2.getTokenPrice(address(xToken));
        console.log("--Dex2TokenPrice:", Dex2TokenPrice);

        if (Dex1TokenPrice == Dex2TokenPrice) {
           revert("Prices are equal");
        }

        if (Dex1TokenPrice < Dex2TokenPrice){
            console.log("Buy from Dex1 sell to Dex2");
            uint256 Dex1TokenBalance = xToken.balanceOf(address(Dex1));
            arbitrage.executeArbitrage(address(xToken), address(Dex1), address(Dex2), Dex1TokenBalance, block.timestamp);
        }
        if (Dex2TokenPrice < Dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            uint256 Dex2TokenBalance = xToken.balanceOf(address(Dex2));
            arbitrage.executeArbitrage(address(xToken), address(Dex2), address(Dex1), Dex2TokenBalance, block.timestamp);
        }
        vm.stopPrank();
        uint finalVaultBalance = vault.tokenBalance(address(xToken));
        assertNotEq(finalVaultBalance, initialVaultBalance);
        uint finalVaultETHBalance = vault.ethBalance();
        assertNotEq(finalVaultETHBalance, initialVaultETHBalance);
        */
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
