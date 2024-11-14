// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {FunctionsTest} from "./Functions.sol";

contract ArbitrageTest is Test {
    address public ownerAddress;
    address public xTokenAddress;
    FunctionsTest public functionsTest;
    XToken public xToken;
    Router public router1;
    Router public router2;
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;
    uint256 public initialRouter1TokenPrice = 120;
    uint256 public initialRouter2TokenPrice = 80;
    uint256 public initialArbitrageTokens = 5e18;
    string public expectedStatusOk = "0x1";
    uint public expectedTxHashLength = 66;

    function setUp() public {
        //_testMint();
        ownerAddress = vm.envAddress("WALLET_ADDRESS");
        functionsTest = new FunctionsTest();
        xTokenAddress = vm.envAddress("XToken");
        console.log("Owner Address:", ownerAddress);
        vm.startPrank(ownerAddress);
        //vm.allowCheatcodes(ownerAddress);
        //vm.allowCheatcodes(xTokenAddress);
        //vm.allowCheatcodes(address(this));
        //xToken = XToken(vm.envAddress("XToken"));
        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        router1 = Router(vm.envAddress("Router1"));
        router2 = Router(vm.envAddress("Router2"));
        vault = Vault(payable(vm.envAddress("Vault")));

        (string memory txHash, string memory status) = functionsTest.mint(vm.envString("XToken"), 1 ether);
        assertEq(expectedStatusOk, status);
        assertEq(expectedTxHashLength, bytes(txHash).length);

        //uint256 xTokenWalletBalance = functions.getTokenBalanceOf(vm.envString("XToken"), vm.envString("WALLET_ADDRESS"));
        //console.log("xTokenWalletBalance:", xTokenWalletBalance);

        //functions.mint(vm.envString("XToken"), 1 ether);
        //bytes memory result = functions.mint(vm.envString("XToken"), 1 ether);
        /*
        if (0 < result.length) {
            bytes memory output = abi.decode(result, (bytes));
            console.log(string(output));
        }else{
            console.log("Error: cast call returned empty result");
            revert("Failed supplyTokensTo()");
        }
        */

/*
        bytes memory result  = functions.supplyTokensTo(vm.envString("XToken"), vm.envString("Router1"),1 ether);
        if (0 < result.length) {
            bytes memory output = abi.decode(result, (bytes));
            console.log(string(output));
        }else{
            console.log("Error: cast call returned empty result");
            revert("Failed supplyTokensTo()");
        }

        vm.stopPrank();
*/
/*
        console.log("Arbitrage Address:", address(arbitrage));
        console.log("Router1 Address:", address(router1));
        console.log("Router2 Address:", address(router2));
        console.log("Vault Address:", address(vault));
        console.log("XToken Address:", address(xToken));
        _initializeTokenPrices();
        _addLiquidityAndApprovals();
        vm.stopPrank();
        console.log("Setup completed successfully.");
        */
    }
/*
    function _testMint() public {
        console.log("Testing mint function.");
        // Example of calling the mint function using the contract instance
        xToken.supplyTokenTo(address(this), 1 ether);

        // You can add assertions here to check the state of the contract
        uint256 balance = xToken.getTokenBalanceAt(address(this));
        assertEq(balance, 1 ether, "Balance should be 1 ether");
    }

    // Helper function to initialize and verify token prices
    function _initializeTokenPrices() internal {
        console.log("owner:", ownerAddress);
        console.log("msg.sender:", msg.sender);
        //require(msg.sender == owner, "Not authorized");
        console.log("Function Initialize Token Prices");
        //xToken.approve(address(router1), type(uint256).max);
        //xToken.approve(address(router2), type(uint256).max);
        router1.setTokenPrice(address(xToken), initialRouter1TokenPrice);
        router2.setTokenPrice(address(xToken), initialRouter2TokenPrice);

        uint256 router1TokenPrice = router1.getTokenPrice(address(xToken));
        uint256 router2TokenPrice = router2.getTokenPrice(address(xToken));

        require(router1TokenPrice == initialRouter1TokenPrice, "Router1 token price mismatch");
        require(router2TokenPrice == initialRouter2TokenPrice, "Router2 token price mismatch");

        console.log("@router1TokenPrice:", router1TokenPrice);
        console.log("@router2TokenPrice:", router2TokenPrice);
    }

    // Helper function to add liquidity and set approvals
    function _addLiquidityAndApprovals() internal {
        xToken.supplyTokenTo(address(this), initialArbitrageTokens);
        uint256 thisBalance = xToken.getTokenBalanceAt(address(this));
        assertEq(xToken.getTokenBalanceAt(address(this)), initialArbitrageTokens);

        uint256 router1Tokens = thisBalance / 2;
        console.log("@78 router1Tokens:", router1Tokens);
        xToken.supplyTokenTo(address(router1), router1Tokens);
        uint256 router1Balance = xToken.getTokenBalanceAt(address(router1));
        console.log("@80 router1Balance:", router1Balance);

        uint256 router2Tokens = thisBalance / 4;
        xToken.supplyTokenTo(address(router2), thisBalance / 4);
        uint256 router2Balance = xToken.getTokenBalanceAt(address(router2));
        assertEq(router2Balance, router2Tokens);

        console.log("Initial token balances:");
        console.log("XToken@thisBalance:", thisBalance);
        console.log("router1Balance:", router1Balance);
        console.log("router2Balance:", router2Balance);
    }
*/
    function test_executeArbitrage()public{
        console.log("Function Test ExecuteArbitrage");

        /*
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
