// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Dex} from "../src/Dex.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";

contract SingleArbitrageTest is Test {
    address public ownerAddress;
    address public xTokenAddress;
    CastFunctionsTest public castFunctionsTest;
    ConversionsTest public conversionsTest;
    XToken public xToken;
    Dex public dex1;
    Dex public dex2;
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;
    uint256 public initialRouter1TokenPrice = 120;
    uint256 public initialRouter2TokenPrice = 80;
    uint256 public initialArbitrageTokens = 5e18;
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;

    function setUp() public {
        ownerAddress = vm.envAddress("WALLET_ADDRESS");
        castFunctionsTest = new CastFunctionsTest();
        conversionsTest = new ConversionsTest();
        xTokenAddress = vm.envAddress("XToken");
        console.log("Owner Address:", ownerAddress);
        //vm.startPrank(ownerAddress);
        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        dex1 = Router(vm.envAddress("Router1"));
        dex2 = Router(vm.envAddress("Router2"));
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

        uint256 walletBalance = castFunctionsTest.addressBalance(vm.envString("WALLET_ADDRESS"));
        console.log("walletBalanceX:", walletBalance);

        uint256 xTokenWalletBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("XToken"), vm.envString("WALLET_ADDRESS"));
        console.log("xTokenWalletBalance:", xTokenWalletBalance);

        (string memory txHash, string memory status) = castFunctionsTest.mint(vm.envString("XToken"), 1 ether);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.supplyTokensTo(vm.envString("XToken"), vm.envString("Router1"),1 ether);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.supplyTokensTo(vm.envString("XToken"), vm.envString("Router2"),1 ether);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.approve(vm.envString("XToken"), vm.envString("Router1"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.approve(vm.envString("XToken"), vm.envString("Router2"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("Router1"), vm.envString("XToken"), initialRouter1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("Router2"), vm.envString("XToken"), initialRouter2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 router1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Router1"), vm.envString("XToken"));
        assertEq(router1TokenPrice, initialRouter1TokenPrice);

        uint256 router2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Router2"), vm.envString("XToken"));
        assertEq(router2TokenPrice, initialRouter2TokenPrice);




        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
        uint256 gasStart = gasleft();
        uint256 router1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Router1"), vm.envString("XToken"));
        console.log("--router1TokenPrice:", router1TokenPrice);
        uint256 router2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("Router2"), vm.envString("XToken"));
        console.log("--router2TokenPrice:", router2TokenPrice);

        uint256 router1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Router1"), vm.envString("XToken"));
        console.log("--router1TokenBalance:", router1TokenBalance);
        uint256 router2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("Router2"), vm.envString("XToken"));
        console.log("--router2TokenBalance:", router2TokenBalance);

        if (router1TokenPrice == router2TokenPrice) {
            revert("Prices are equal");
        }

        if (router1TokenPrice < router2TokenPrice){
            console.log("Buy from router1 sell to router2");
            arbitrage.executeArbitrage(address(xToken), address(dex1), address(dex2), router1TokenBalance, block.timestamp);
        }
        if (router2TokenPrice < router1TokenPrice){
            console.log("Buy from router2 sell to router1");
            arbitrage.executeArbitrage(address(xToken), address(dex2), address(dex1), router2TokenBalance, block.timestamp);
        }

        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used:", gasUsed);

        /*

        arbitrage.executeArbitrage(address(xToken), address(router1), address(router2), 1 ether, block.timestamp);
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
        uint256 router1TokenPrice = router1.getTokenPrice(address(xToken));
        console.log("--router1 address:", address(router1));
        console.log("--router1TokenPrice:", router1TokenPrice);
        console.log("--router2 address:", address(router2));
        uint256 router2TokenPrice = router2.getTokenPrice(address(xToken));
        console.log("--router2TokenPrice:", router2TokenPrice);

        if (router1TokenPrice == router2TokenPrice) {
           revert("Prices are equal");
        }

        if (router1TokenPrice < router2TokenPrice){
            console.log("Buy from router1 sell to router2");
            uint256 router1TokenBalance = xToken.balanceOf(address(router1));
            arbitrage.executeArbitrage(address(xToken), address(router1), address(router2), router1TokenBalance, block.timestamp);
        }
        if (router2TokenPrice < router1TokenPrice){
            console.log("Buy from router2 sell to router1");
            uint256 router2TokenBalance = xToken.balanceOf(address(router2));
            arbitrage.executeArbitrage(address(xToken), address(router2), address(router1), router2TokenBalance, block.timestamp);
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
