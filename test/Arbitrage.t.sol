// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/PigfoxToken.sol";
import "../src/IDex.sol";
import "../src/Arbitrage.sol";

contract ArbitrageTest is Test {
    PigfoxToken public pigfoxToken;
    IDex public dex1;
    IDex public dex2;
    Arbitrage public arbitrage;
    address public wallet;

    // Environment variables as constants
    string constant SEPOLIA_RPC_URL = "SEPOLIA_HTTP_RPC_URL";
    string constant WALLET_ADDRESS = "WALLET_ADDRESS";
    string constant PIGFOX_TOKEN = "PIGFOX_TOKEN";
    string constant DEX1 = "DEX1";
    string constant DEX2 = "DEX2";
    string constant ARBITRAGE = "ARBITRAGE";
    string constant BURN_ADDRESS = "BURN_ADDRESS";

    // Constants for token and ETH amounts
    uint256 constant DECIMALS = 10**18;              // Standard ERC20 decimal places
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS; // 100 PFX
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;        // 50 PFX
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;           // 10 PFX
    uint256 constant ETH_FUNDING = 1 * DECIMALS;             // 1 ETH
    uint256 constant WALLET_ETH_BUFFER = 2 * DECIMALS;       // 2 ETH

    // Constants for DEX prices
    uint256 constant DEX1_PRICE = 120;               // 120 wei/PFX
    uint256 constant DEX2_PRICE = 80;                // 80 wei/PFX

    // Constant for deadline extension
    uint256 constant DEADLINE_EXTENSION = 1000;      // 1000 seconds

    function setUp() public {
        // Fork Sepolia to interact with deployed contracts
        string memory rpcUrl = vm.envString(SEPOLIA_RPC_URL);
        vm.createSelectFork(rpcUrl);

        // Fetch addresses from environment variables
        wallet = vm.envAddress(WALLET_ADDRESS);
        address pigfoxTokenAddr = vm.envAddress(PIGFOX_TOKEN);
        address dex1Addr = vm.envAddress(DEX1);
        address dex2Addr = vm.envAddress(DEX2);
        address arbitrageAddr = vm.envAddress(ARBITRAGE);

        // Cast deployed contract addresses to their respective types
        pigfoxToken = PigfoxToken(pigfoxTokenAddr);
        dex1 = IDex(dex1Addr);
        dex2 = IDex(dex2Addr);
        arbitrage = Arbitrage(payable(arbitrageAddr));

        // Log initial state
        console.log("Wallet Address:", wallet);
        console.log("PigfoxToken Address:", address(pigfoxToken));
        console.log("DEX1 Address:", address(dex1));
        console.log("DEX2 Address:", address(dex2));
        console.log("Arbitrage Address:", address(arbitrage));

        // Start prank as wallet
        vm.startPrank(wallet);

        // Check and ensure wallet has PFX tokens
        uint256 walletBalance = pigfoxToken.balanceOf(wallet);
        console.log("Wallet PFX Balance:");
        console2.log(walletBalance);
        if (walletBalance < MIN_WALLET_PFX_BALANCE) {
            console.log("Warning: Wallet has insufficient PFX. Attempting to mint...");
            try pigfoxToken.mint(MIN_WALLET_PFX_BALANCE) {
                console.log("Minted 100 PFX to wallet");
            } catch {
                console.log("Mint failed. Ensure wallet is owner or has sufficient PFX.");
                vm.stopPrank();
                return; // Exit setup if minting fails
            }
        }

        // Check DEX balances and fund if empty
        uint256 dex1Balance = pigfoxToken.balanceOf(dex1Addr);
        uint256 dex2Balance = pigfoxToken.balanceOf(dex2Addr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1Balance);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2Balance);

        if (dex1Balance < DEX_PFX_DEPOSIT) {
            pigfoxToken.approve(dex1Addr, DEX_PFX_DEPOSIT);
            pigfoxToken.transfer(dex1Addr, DEX_PFX_DEPOSIT);
            console.log("Transferred 50 PFX to DEX1");
        }
        if (dex2Balance < DEX_PFX_DEPOSIT) {
            pigfoxToken.approve(dex2Addr, DEX_PFX_DEPOSIT);
            pigfoxToken.transfer(dex2Addr, DEX_PFX_DEPOSIT);
            console.log("Transferred 50 PFX to DEX2");
        }

        // Fund arbitrage contract with ETH
        uint256 arbitrageEth = address(arbitrage).balance;
        console.log("Arbitrage ETH Balance:");
        console2.log(arbitrageEth);
        if (arbitrageEth < ETH_FUNDING) {
            vm.deal(wallet, WALLET_ETH_BUFFER); // Ensure wallet has ETH for funding
            (bool sent, ) = address(arbitrage).call{value: ETH_FUNDING}("");
            require(sent, "Failed to fund arbitrage contract with ETH");
            console.log("Funded arbitrage with 1 ETH");
        }

        // Ensure wallet is an accessor (assuming addAccessor exists in Arbitrage)
        if (!arbitrage.accessors(wallet)) {
            arbitrage.addAccessor(wallet);
            console.log("Wallet added as accessor");
        }

        // Set initial prices on DEXes if not already set
        uint256 dex1Price = dex1.getTokenPrice(address(pigfoxToken));
        uint256 dex2Price = dex2.getTokenPrice(address(pigfoxToken));
        if (dex1Price == 0) {
            dex1.setTokenPrice(address(pigfoxToken), DEX1_PRICE);
            console.log("Set DEX1 price to 120 wei/PFX");
        }
        if (dex2Price == 0) {
            dex2.setTokenPrice(address(pigfoxToken), DEX2_PRICE);
            console.log("Set DEX2 price to 80 wei/PFX");
        }

        vm.stopPrank();
    }

    function test_executeArbitrage() public {
        vm.startPrank(wallet);

        // Log initial state
        uint256 initialEth = address(arbitrage).balance;
        uint256 initialProfitEth = wallet.balance;
        console.log("Initial Arbitrage ETH:");
        console2.log(initialEth);
        console.log("Initial Wallet ETH:");
        console2.log(initialProfitEth);

        // Check prices using getTokenPrice
        uint256 dex1Price = dex1.getTokenPrice(address(pigfoxToken));
        uint256 dex2Price = dex2.getTokenPrice(address(pigfoxToken));
        console.log("DEX1 Price (wei/PFX):");
        console2.log(dex1Price);
        console.log("DEX2 Price (wei/PFX):");
        console2.log(dex2Price);

        // Ensure arbitrage opportunity exists
        require(dex2Price < dex1Price, "No arbitrage opportunity: DEX2 price >= DEX1 price");

        // Execute arbitrage: Buy from DEX2 (cheaper), sell to DEX1 (expensive)
        arbitrage.run(
            address(pigfoxToken),
            address(dex2), // Buy from cheaper DEX
            address(dex1), // Sell to expensive DEX
            TRADE_AMOUNT,  // 10 PFX
            block.timestamp + DEADLINE_EXTENSION
        );

        // Log final state
        uint256 finalEth = address(arbitrage).balance;
        uint256 finalProfitEth = wallet.balance;
        console.log("Final Arbitrage ETH:", finalEth);
        console.log("Final Wallet ETH:", finalProfitEth);

        // Verify profit
        uint256 profit = finalProfitEth - initialProfitEth;
        assertGt(profit, 0, "No profit made");
        console.log("Profit (ETH wei):", profit);

        vm.stopPrank();
    }
}