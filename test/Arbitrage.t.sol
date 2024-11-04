// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import {Vault} from "../src/Vault.sol";
import {Functions} from "./Functions.sol";

contract ArbitrageTest is Test {
    address public ownerAddress;
    address public xTokenAddress;
    Functions public functions;
    XToken public xToken;
    Router public router1;
    Router public router2;
    Arbitrage public arbitrage;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;
    uint256 public initialRouter1TokenPrice = 120;
    uint256 public initialRouter2TokenPrice = 80;
    uint256 public initialArbitrageTokens = 5e18;

    function setUp() public {
        ownerAddressStr = vm.envString("WALLET_ADDRESS");
        xTokenAddressStr = vm.envString("XToken");
        console.log("Owner Address:", ownerAddressStr);
        vm.startPrank(address(ownerAddressStr));
        vm.allowCheatcodes(address(ownerAddressStr));
        vm.allowCheatcodes(address(xTokenAddressStr));
        functions = new Functions();
        //xToken = XToken(vm.envAddress("XToken"));
        xToken = functions.getXTokens(vm.envString("XToken"), ownerAddressStr);
        arbitrage = Arbitrage(vm.envAddress("Arbitrage"));
        router1 = Router(vm.envAddress("Router1"));
        router2 = Router(vm.envAddress("Router2"));
        vault = Vault(payable(vm.envAddress("Vault")));


        console.log("Arbitrage Address:", address(arbitrage));
        console.log("Router1 Address:", address(router1));
        console.log("Router2 Address:", address(router2));
        console.log("Vault Address:", address(vault));
        console.log("XToken Address:", address(xToken));
        _initializeTokenPrices();
        _addLiquidityAndApprovals();
        vm.stopPrank();
        console.log("Setup completed successfully.");
    }

    // Helper function to initialize and verify token prices
    function _initializeTokenPrices() internal {
        console.log("owner:", ownerAddressStr);
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

    function test_executeArbitrage()public{
        vm.startPrank(ownerAddressStr);
        console.log("Function Test SwapTokens");
        address arbitrageOwner = arbitrage.owner();
        console.log("arbitrageOwner:",arbitrageOwner);
        assert(msg.sender == ownerAddressStr, "Not authorized");
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
    }

    function test_setProfitAddress()public{
        vm.startPrank(ownerAddressStr);
        console.log("Function Test SetProfitAddress");
        address profitAddress = vm.envAddress("WALLET_ADDRESS");
        arbitrage.setProfitAddress(profitAddress);
        vm.stopPrank();
        assertEq(arbitrage.profitAddress(), profitAddress);
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

    function _setPrank() internal {
        vm.startPrank(ownerAddressStr);
    }

    /*
    function tearDown() public {
        vm.stopPrank(); // Ensure prank is stopped after each test
    }
    */
}
