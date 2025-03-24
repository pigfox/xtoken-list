// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/PigfoxToken.sol";
import "../src/IDex.sol";
import "../src/Arbitrage.sol";
import "../src/Vault.sol"; // Include Vault interface

contract ArbitrageTest is Test {
    PigfoxToken public pigfoxToken;
    IDex public dex1;
    IDex public dex2;
    Arbitrage public arbitrage;
    Vault public vault;
    address public walletAddr;

    // Environment variables as constants
    string constant SEPOLIA_RPC_URL = "SEPOLIA_HTTP_RPC_URL";
    string constant WALLET_ADDRESS = "WALLET_ADDRESS";
    string constant PIGFOX_TOKEN = "PIGFOX_TOKEN";
    string constant DEX1 = "DEX1";
    string constant DEX2 = "DEX2";
    string constant ARBITRAGE = "ARBITRAGE";
    string constant BURN_ADDRESS = "BURN_ADDRESS";
    string constant VAULT = "VAULT";

    // Constants for token and ETH amounts
    uint256 constant DECIMALS = 10**18;              // Standard ERC20 decimal places
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS; // 100 PFX
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;        // 50 PFX
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;           // 10 PFX
    uint256 constant ETH_FUNDING = 1 * DECIMALS;             // 1 ETH
    uint256 constant WALLET_ETH_BUFFER = 2 * DECIMALS;       // 2 ETH
    uint256 constant VAULT_ETH_FUNDING = 10 * DECIMALS;      // 10 ETH for flash loans
    uint256 constant ARBITRAGE_ETH_FUNDING = 1 * DECIMALS;   // 1 ETH for Arbitrage
    uint256 constant DEX_ETH_FUNDING = 1 * DECIMALS;         // 1 ETH for each DEX

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
        walletAddr = vm.envAddress(WALLET_ADDRESS);
        address pigfoxTokenAddr = vm.envAddress(PIGFOX_TOKEN);
        address dex1Addr = vm.envAddress(DEX1);
        address dex2Addr = vm.envAddress(DEX2);
        address arbitrageAddr = vm.envAddress(ARBITRAGE);
        address vaultAddr = vm.envAddress(VAULT);

        // Cast deployed contract addresses to their respective types
        pigfoxToken = PigfoxToken(pigfoxTokenAddr);
        dex1 = IDex(dex1Addr);
        dex2 = IDex(dex2Addr);
        arbitrage = Arbitrage(payable(arbitrageAddr));
        vault = Vault(payable(vaultAddr));

        // Log initial state
        console.log("Wallet Address:", walletAddr);
        console.log("PigfoxToken Address:", address(pigfoxToken));
        console.log("DEX1 Address:", address(dex1));
        console.log("DEX2 Address:", address(dex2));
        console.log("Arbitrage Address:", address(arbitrage));
        console.log("Vault Address:", address(vault));

        // Start prank as wallet
        vm.startPrank(walletAddr);

        // Check and ensure wallet has PFX tokens
        uint256 walletBalance = pigfoxToken.balanceOf(walletAddr);
        console.log("Wallet PFX Balance:");
        console2.logUint(walletBalance);
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

        // Check DEX1 balance and fund if empty (for selling PFX back)
        uint256 dex1Balance = pigfoxToken.balanceOf(dex1Addr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1Balance);
        if (dex1Balance < DEX_PFX_DEPOSIT) {
            pigfoxToken.approve(dex1Addr, DEX_PFX_DEPOSIT);
            dex1.depositTokens(address(pigfoxToken), DEX_PFX_DEPOSIT);
            console.log("Deposited 50 PFX to DEX1");
        }

        // Check DEX2 balance and fund if empty (for buying PFX)
        uint256 dex2Balance = pigfoxToken.balanceOf(dex2Addr);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2Balance);
        if (dex2Balance < DEX_PFX_DEPOSIT) {
            pigfoxToken.approve(dex2Addr, DEX_PFX_DEPOSIT);
            dex2.depositTokens(address(pigfoxToken), DEX_PFX_DEPOSIT);
            console.log("Deposited 50 PFX to DEX2");
        }

        // Fund Vault, Arbitrage, and DEXes with ETH
        uint256 vaultEthBalance = address(vault).balance;
        console.log("Vault ETH Balance:");
        console2.logUint(vaultEthBalance);
        if (vaultEthBalance < VAULT_ETH_FUNDING) {
            // Ensure wallet has enough ETH (10 ETH for Vault + 1 ETH for Arbitrage + 1 ETH for each DEX + buffer)
            uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
            vm.deal(walletAddr, requiredEth); // Fund wallet with 15 ETH (10 + 1 + 1 + 1 + 2)
            console.log("Wallet funded with:");
            console2.logUint(requiredEth / DECIMALS);
            console.log("ETH");

            // Verify wallet balance before deposits
            uint256 walletEthBalance = walletAddr.balance;
            console.log("Wallet ETH Balance before deposit:");
            console2.logUint(walletEthBalance / DECIMALS);
            console.log("ETH");
            require(walletEthBalance >= VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING), "Insufficient ETH in wallet");

            // Deposit ETH to Vault
            vault.depositETH{value: VAULT_ETH_FUNDING}();
            console.log("Funded Vault with 10 ETH");

            // Fund Arbitrage contract with ETH
            (bool successArb, ) = address(arbitrage).call{value: ARBITRAGE_ETH_FUNDING}("");
            require(successArb, "Failed to fund Arbitrage contract");
            console.log("Funded Arbitrage with 1 ETH");

            // Fund DEX1 with ETH
            (bool successDex1, ) = address(dex1).call{value: DEX_ETH_FUNDING}("");
            require(successDex1, "Failed to fund DEX1");
            console.log("Funded DEX1 with 1 ETH");

            // Fund DEX2 with ETH (optional, for symmetry)
            (bool successDex2, ) = address(dex2).call{value: DEX_ETH_FUNDING}("");
            require(successDex2, "Failed to fund DEX2");
            console.log("Funded DEX2 with 1 ETH");
        }

        // Ensure wallet is an accessor (assuming addAccessor exists in Arbitrage)
        if (!arbitrage.accessors(walletAddr)) {
            arbitrage.addAccessor(walletAddr);
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
        vm.startPrank(walletAddr);

        // Log initial state
        uint256 initialArbEth = address(arbitrage).balance;
        uint256 initialWalletEth = walletAddr.balance;
        console.log("Initial Arbitrage ETH:");
        console2.logUint(initialArbEth);
        console.log("Initial Wallet ETH:");
        console2.logUint(initialWalletEth);

        // Check prices using getTokenPrice
        uint256 dex1Price = dex1.getTokenPrice(address(pigfoxToken));
        uint256 dex2Price = dex2.getTokenPrice(address(pigfoxToken));
        console.log("DEX1 Price (wei/PFX):");
        console2.logUint(dex1Price);
        console.log("DEX2 Price (wei/PFX):");
        console2.logUint(dex2Price);

        // Ensure arbitrage opportunity exists
        require(dex2Price < dex1Price, "No arbitrage opportunity: DEX2 price >= DEX1 price");

        // Execute arbitrage: Buy from DEX2, sell to DEX1, profit to wallet
        arbitrage.run(
            address(pigfoxToken),
            address(dex2), // Buy from cheaper DEX
            address(dex1), // Sell to expensive DEX
            TRADE_AMOUNT,  // 10 PFX
            block.timestamp + DEADLINE_EXTENSION
        );

        // Log final state
        uint256 finalArbEth = address(arbitrage).balance;
        uint256 finalWalletEth = walletAddr.balance;
        console.log("Final Arbitrage ETH:");
        console2.logUint(finalArbEth);
        console.log("Final Wallet ETH:");
        console2.logUint(finalWalletEth);

        // Verify profit (profit is sent to wallet)
        uint256 profit = finalWalletEth - initialWalletEth;
        assertGt(profit, 0, "No profit made");
        console.log("Profit (ETH wei):");
        console2.logUint(profit);

        vm.stopPrank();
    }
}