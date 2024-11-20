// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {SingleTokenDex} from "../src/SingleTokenDex.sol";
import {XToken} from "../src/XToken.sol";
import {SingleTokenArbitrage} from "../src/SingleTokenArbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {CastFunctionsTest} from "./CastFunctions.sol";
import {ConversionsTest} from "./Conversions.sol";

contract SingleTokenArbitrageTest is Test {
    address public ownerAddress;
    address public xTokenAddress;
    CastFunctionsTest public castFunctionsTest;
    ConversionsTest public conversionsTest;
    XToken public xToken;
    SingleTokenDex public singleTokenDex1;
    SingleTokenDex public singleTokenDex2;
    SingleTokenArbitrage public singleTokenArbitrage;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;
    uint256 public initialSingleTokenDex1TokenSupply = 3e18;
    uint256 public initialSingleTokenDex2TokenSupply = 2e18;

    uint256 public initialSingleTokenDex1TokenPrice = 120;
    uint256 public initialSingleTokenDex2TokenPrice = 80;

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
        singleTokenArbitrage = SingleTokenArbitrage(vm.envAddress("SingleTokenArbitrage"));
        singleTokenDex1 = SingleTokenDex(vm.envAddress("SingleTokenDex1"));
        singleTokenDex2 = SingleTokenDex(vm.envAddress("SingleTokenDex2"));
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
        (string memory txHash, string memory  status) = castFunctionsTest.emptyDex(vm.envString("SingleTokenDex1"), vm.envString("XToken"), vm.envString("TrashCan"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.emptyDex(vm.envString("SingleTokenDex2"), vm.envString("XToken"), vm.envString("TrashCan"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 walletBalance = castFunctionsTest.addressBalance(vm.envString("WALLET_ADDRESS"));
        console.log("walletBalanceX:", walletBalance);

        uint256 xTokenWalletBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("XToken"), vm.envString("WALLET_ADDRESS"));
        console.log("xTokenWalletBalance:", xTokenWalletBalance);

        (txHash, status) = castFunctionsTest.mint(vm.envString("XToken"), 1 ether);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.supplyTokensTo(vm.envString("XToken"), vm.envString("SingleTokenDex1"),initialSingleTokenDex1TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 SingleTokenDex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("XToken"), vm.envString("SingleTokenDex1"));
        assertEq(SingleTokenDex1TokenBalance, initialSingleTokenDex1TokenSupply);

        (txHash, status) = castFunctionsTest.supplyTokensTo(vm.envString("XToken"), vm.envString("SingleTokenDex2"),initialSingleTokenDex2TokenSupply);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 SingleTokenDex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("XToken"), vm.envString("SingleTokenDex2"));
        assertEq(SingleTokenDex2TokenBalance, initialSingleTokenDex2TokenSupply);

        (txHash, status) = castFunctionsTest.approve(vm.envString("XToken"), vm.envString("SingleTokenDex1"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.approve(vm.envString("XToken"), vm.envString("SingleTokenDex2"));
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("SingleTokenDex1"), vm.envString("XToken"), initialSingleTokenDex1TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        (txHash, status) = castFunctionsTest.setTokenPrice(vm.envString("SingleTokenDex2"), vm.envString("XToken"), initialSingleTokenDex2TokenPrice);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        uint256 SingleTokenDex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("SingleTokenDex1"), vm.envString("XToken"));
        assertEq(SingleTokenDex1TokenPrice, initialSingleTokenDex1TokenPrice);

        uint256 SingleTokenDex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("SingleTokenDex2"), vm.envString("XToken"));
        assertEq(SingleTokenDex2TokenPrice, initialSingleTokenDex2TokenPrice);

        console.log("Setup completed successfully.");
    }

    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");
/*
        uint256 gasStart = gasleft();
        uint256 SingleTokenDex1TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("SingleTokenDex1"), vm.envString("XToken"));
        console.log("--SingleTokenDex1TokenPrice:", SingleTokenDex1TokenPrice);
        uint256 SingleTokenDex2TokenPrice = castFunctionsTest.getTokenPrice(vm.envString("SingleTokenDex2"), vm.envString("XToken"));
        console.log("--SingleTokenDex2TokenPrice:", SingleTokenDex2TokenPrice);

        uint256 SingleTokenDex1TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("SingleTokenDex1"), vm.envString("XToken"));
        console.log("--SingleTokenDex1TokenBalance:", SingleTokenDex1TokenBalance);
        uint256 SingleTokenDex2TokenBalance = castFunctionsTest.getTokenBalanceOf(vm.envString("SingleTokenDex2"), vm.envString("XToken"));
        console.log("--SingleTokenDex2TokenBalance:", SingleTokenDex2TokenBalance);

        if (SingleTokenDex1TokenPrice == SingleTokenDex2TokenPrice) {
            revert("Prices are equal");
        }

        if (SingleTokenDex1TokenPrice < SingleTokenDex2TokenPrice){
            console.log("Buy from SingleTokenDex1 sell to SingleTokenDex2");
            singleTokenArbitrage.executeArbitrage(address(xToken), address(singleTokenDex1), address(singleTokenDex2), SingleTokenDex1TokenBalance, block.timestamp);
        }
        if (SingleTokenDex2TokenPrice < SingleTokenDex1TokenPrice){
            console.log("Buy from SingleTokenDex2 sell to SingleTokenDex1");
            singleTokenArbitrage.executeArbitrage(address(xToken), address(singleTokenDex2), address(singleTokenDex1), SingleTokenDex2TokenBalance, block.timestamp);
        }

        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used:", gasUsed);
*/
        /*

        arbitrage.executeArbitrage(address(xToken), address(SingleTokenDex1), address(SingleTokenDex2), 1 ether, block.timestamp);
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
        uint256 SingleTokenDex1TokenPrice = SingleTokenDex1.getTokenPrice(address(xToken));
        console.log("--SingleTokenDex1 address:", address(SingleTokenDex1));
        console.log("--SingleTokenDex1TokenPrice:", SingleTokenDex1TokenPrice);
        console.log("--SingleTokenDex2 address:", address(SingleTokenDex2));
        uint256 SingleTokenDex2TokenPrice = SingleTokenDex2.getTokenPrice(address(xToken));
        console.log("--SingleTokenDex2TokenPrice:", SingleTokenDex2TokenPrice);

        if (SingleTokenDex1TokenPrice == SingleTokenDex2TokenPrice) {
           revert("Prices are equal");
        }

        if (SingleTokenDex1TokenPrice < SingleTokenDex2TokenPrice){
            console.log("Buy from SingleTokenDex1 sell to SingleTokenDex2");
            uint256 SingleTokenDex1TokenBalance = xToken.balanceOf(address(SingleTokenDex1));
            arbitrage.executeArbitrage(address(xToken), address(SingleTokenDex1), address(SingleTokenDex2), SingleTokenDex1TokenBalance, block.timestamp);
        }
        if (SingleTokenDex2TokenPrice < SingleTokenDex1TokenPrice){
            console.log("Buy from SingleTokenDex2 sell to SingleTokenDex1");
            uint256 SingleTokenDex2TokenBalance = xToken.balanceOf(address(SingleTokenDex2));
            arbitrage.executeArbitrage(address(xToken), address(SingleTokenDex2), address(SingleTokenDex1), SingleTokenDex2TokenBalance, block.timestamp);
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
