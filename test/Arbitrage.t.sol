// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";

contract ArbitrageTest is Test {
    address public owner;
    Router public router1;
    Router public router2;
    XToken public xToken;
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;

    function setUp() public {
        // Set up the Sepolia fork
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        uint256 forkId = vm.createSelectFork(rpcUrl);
        vm.selectFork(forkId);

        // Load addresses from environment variables
        owner = vm.envAddress("WALLET_ADDRESS");
        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        router1 = Router(vm.envAddress("Router1"));
        router2 = Router(vm.envAddress("Router2"));
        vault = Vault(payable(vm.envAddress("Vault")));
        xToken = XToken(vm.envAddress("XToken"));

        console.log("Loaded contract addresses:");

        // Initialize token prices
        initializeTokenPrices();

        // Add liquidity and check balances
        addLiquidityAndApprovals();

        console.log("Setup completed successfully.");
    }

// Helper function to initialize and verify token prices
    function initializeTokenPrices() internal {
        router1.setTokenPrice(address(xToken), 120);
        router2.setTokenPrice(address(xToken), 80);

        uint256 router1TokenPrice = router1.getTokenPrice(address(xToken));
        uint256 router2TokenPrice = router2.getTokenPrice(address(xToken));

        require(router1TokenPrice == 120, "Router1 token price mismatch");
        require(router2TokenPrice == 80, "Router2 token price mismatch");

        console.log("@router1TokenPrice:", router1TokenPrice);
        console.log("@router2TokenPrice:", router2TokenPrice);
    }

// Helper function to add liquidity and set approvals
    function addLiquidityAndApprovals() internal {
        xToken.supplyTokenTo(address(this), 5e18);
        uint256 thisBalance = xToken.getTokenBalanceAt(address(this));

        xToken.supplyTokenTo(address(router1), thisBalance / 2);
        uint256 router1Balance = xToken.getTokenBalanceAt(address(router1));

        console.log("Initial token balances:");
        console.log("XToken@thisBalance:", thisBalance);
        console.log("router1Balance:", router1Balance);

        // Approve routers for xToken transactions
        xToken.approve(address(router1), type(uint256).max);
        xToken.approve(address(router2), type(uint256).max);
    }

    function test_swapTokens()public view{
        console.log("Function Test SwapTokens");
        uint initialVaultBalance = vault.tokenBalance(address(xToken));
        uint initialVaultETHBalance = vault.ethBalance();
        //vm.startPrank(owner);
        uint256 router1TokenPrice = router1.getTokenPrice(address(xToken));
        console.log("--router1 address:", address(router1));
        console.log("--router1TokenPrice:", router1TokenPrice);

        uint256 router2TokenPrice = router2.getTokenPrice(address(xToken));
        console.log("--router2TokenPrice:", router2TokenPrice);
        if (router1TokenPrice == router2TokenPrice) {
           revert("Prices are equal");
        }
        /*
        if (router1TokenPrice < router2TokenPrice){
            console.log("Buy from router1 sell to router2");
            uint256 router1TokenBalance = xToken.balanceOf(address(router1));
            arbitrage.executeArbitrage(address(xToken), address(router1), address(router2), address(vault),router1TokenBalance);
        }
        if (router2TokenPrice < router1TokenPrice){
            console.log("Buy from router2 sell to router1");
            uint256 router2TokenBalance = xToken.balanceOf(address(router2));
            arbitrage.executeArbitrage(address(xToken), address(router2), address(router1), address(vault),router2TokenBalance);
        }
        vm.stopPrank();
        uint finalVaultBalance = vault.tokenBalance(address(xToken));
        assertNotEq(finalVaultBalance, initialVaultBalance);
        uint finalVaultETHBalance = vault.ethBalance();
        assertNotEq(finalVaultETHBalance, initialVaultETHBalance);
        */
    }

    function bytes32ToString(bytes32 _data) internal pure returns (string memory) {
        bytes memory tempBytes = new bytes(32);
        uint8 length = 0;

        for (uint8 i = 0; i < 32; i++) {
            bytes1 char = _data[i]; // Use bytes1 instead of byte
            if (char != 0) {
                tempBytes[length] = char;
                length++;
            } else {
                break;
            }
        }

        bytes memory result = new bytes(length);
        for (uint8 j = 0; j < length; j++) {
            result[j] = tempBytes[j];
        }

        return string(result);
    }
}
