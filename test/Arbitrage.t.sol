// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "./CastFunctions.sol";

contract ArbitrageTest is Test {
    string private txHash;
    uint256 private code;
    uint256 constant DEADLINE = 3667;
    uint256 constant DECIMALS = 10 ** 18;
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS;
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;
    uint256 constant VAULT_ETH_FUNDING = 10 ** 16; // 0.01 ETH for vault
    uint256 constant ARBITRAGE_ETH_FUNDING = 10 ** 15; // 0.001 ETH for arbitrage
    uint256 constant DEX_ETH_FUNDING = 10 ** 15; // 0.001 ETH per DEX
    uint256 constant WALLET_ETH_BUFFER = 10 ** 17; // 0.1 ETH buffer

    uint256 constant DEX1_PRICE = 120; // wei/PFX
    uint256 constant DEX2_PRICE = 80; // wei/PFX

    address private pigfoxTokenAddr = vm.envAddress("PIGFOX_TOKEN");
    address private dex1Addr = vm.envAddress("DEX1");
    address private dex2Addr = vm.envAddress("DEX2");
    address private arbitrageAddr = vm.envAddress("ARBITRAGE");
    address private vaultAddr = vm.envAddress("VAULT");
    address private walletAddr = vm.envAddress("WALLET_ADDRESS");
    address private chromeWalletAddr = vm.envAddress("CHROME_WALLET");
    address private flashLoanAddr1 = vm.envAddress("FLASHLOAN_1");
    address private flashLoanAddr2 = vm.envAddress("FLASHLOAN_2");
    string private walletPrivateKeyStr = vm.envString("WALLET_PRIVATE_KEY");
    string private chromeWalletPrivateKeyStr = vm.envString("CHROME_WALLET_PRIVATE_KEY");

    function logTxHash(string memory _txHash, string memory _action) internal view {
        string memory url = string(abi.encodePacked("https://sepolia.etherscan.io/tx/", _txHash));
        console.log("[tx] %s -> %s", _action, url);
    }

    function setUp() public {
        CastFunctions castFunctions = new CastFunctions();

        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(walletAddr, pigfoxTokenAddr);
        //console.log("Wallet PFX Balance:");
        //console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            //pigfoxToken.mint(MIN_WALLET_PFX_BALANCE);
            (txHash, code) = castFunctions.mint(pigfoxTokenAddr, MIN_WALLET_PFX_BALANCE);
            if (code == 1) {
                logTxHash(txHash, string.concat("Minted ", vm.toString(MIN_WALLET_PFX_BALANCE), " PFX to wallet (on Sepolia)"));
            }
        }

        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        //console.log("DEX1 PFX Balance:");
        //console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            castFunctions.approve(pigfoxTokenAddr, walletAddr, ARBITRAGE_ETH_FUNDING);
            (txHash, code) = castFunctions.depositTokens(dex1Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            if (code == 1) {
                logTxHash(txHash, string.concat("Deposited ", vm.toString(DEX_PFX_DEPOSIT), " PFX to DEX1 (on Sepolia)"));
            }
        }

        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        //console.log("DEX2 PFX Balance:");
        //console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            castFunctions.approve(pigfoxTokenAddr, walletAddr, ARBITRAGE_ETH_FUNDING);
            (txHash, code) = castFunctions.depositTokens(dex2Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            if (code == 1) {
                logTxHash(txHash, string.concat("Deposited ", vm.toString(DEX_PFX_DEPOSIT), " PFX to DEX2 (on Sepolia)"));
            }
        }

        uint256 walletEthBalance = castFunctions.addressBalance(walletAddr);
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        //console.log("Wallet ETH Balance:");
        //console2.logUint(walletEthBalance);
        require(walletEthBalance >= requiredEth, "Wallet needs at least 0.113 ETH on Sepolia");

        (txHash, code) = castFunctions.fundEth(vaultAddr, VAULT_ETH_FUNDING);
        if (code == 1) {
            console.log(string.concat("Funded Vault with ", vm.toString(VAULT_ETH_FUNDING), " ETH (on Sepolia)"));
        } else {
            console.log(
                string.concat("Failed to fund Vault with ", vm.toString(VAULT_ETH_FUNDING), " ETH - proceeding without Vault funding")
            );
        }

        (txHash, code) = castFunctions.setTokenPrice(dex1Addr, pigfoxTokenAddr, DEX1_PRICE);
        (txHash, code) = castFunctions.setTokenPrice(dex2Addr, pigfoxTokenAddr, DEX2_PRICE);
    }

    function test_Setup() public view {
        console.log("Wallet Address:", walletAddr);
        console.log("Chrome Wallet Address:", chromeWalletAddr);
        console.log("PigfoxToken Address:", pigfoxTokenAddr);
        console.log("DEX1 Address:", dex1Addr);
        console.log("DEX2 Address:", dex2Addr);
        console.log("Arbitrage Address:", arbitrageAddr);
        console.log("Vault Address:", vaultAddr);
        console.log("FlashLoan1 Address:", flashLoanAddr1);
        console.log("FlashLoan2 Address:", flashLoanAddr2);
    }

    function test_switchOwner() public {
        CastFunctions castFunctions = new CastFunctions();
        address newOwner;
        address currentOwner = castFunctions.getOwner(arbitrageAddr);
        bool condition = (currentOwner == walletAddr) || (currentOwner == chromeWalletAddr);
        assertTrue(condition, "Invalid wallets for owner switch");

        if (currentOwner == walletAddr) {
            //console.log("Current Owner is wallet address");
            (txHash, code) = castFunctions.setOwner(arbitrageAddr, chromeWalletAddr, walletAddr, walletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set new owner");

            newOwner = castFunctions.getOwner(arbitrageAddr);
            console.log("New Owner is wallet address", newOwner);
            assertEq(newOwner, chromeWalletAddr, "Owner should be updated to chrome wallet address");
        } else if (currentOwner == chromeWalletAddr) {
            console.log("Current Owner is Chrome wallet address");
            (txHash, code) = castFunctions.setOwner(arbitrageAddr, walletAddr, chromeWalletAddr, chromeWalletPrivateKeyStr);

            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set new owner");
            newOwner = castFunctions.getOwner(arbitrageAddr);
            //console.log("New Owner is wallet address", newOwner);
            assertEq(newOwner, walletAddr, "Owner should be updated to wallet address");
        }
    }

    function test_setDeadline() public {
        CastFunctions castFunctions = new CastFunctions();
        address currentOwner = castFunctions.getOwner(arbitrageAddr);
        bool condition = (currentOwner == walletAddr) || (currentOwner == chromeWalletAddr);
        assertTrue(condition, "Invalid wallets for owner check");

        uint256 retrievedDeadline;

        if (currentOwner == walletAddr) {
            (txHash, code) = castFunctions.setDeadline(arbitrageAddr, DEADLINE, walletAddr, walletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            assertEq(code, 1, "Failed to set deadline");
            retrievedDeadline = castFunctions.getDeadline(arbitrageAddr);
            assertEq(retrievedDeadline, DEADLINE, "Deadline should be updated correctly");
        } else if (currentOwner == chromeWalletAddr) {
            (txHash, code) = castFunctions.setDeadline(arbitrageAddr, DEADLINE, chromeWalletAddr, chromeWalletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            assertEq(code, 1, "Failed to set deadline");
            retrievedDeadline = castFunctions.getDeadline(arbitrageAddr);
            assertEq(retrievedDeadline, DEADLINE, "Deadline should be updated correctly");
        }
    }


    function test_setProfitAddress() public {
        CastFunctions castFunctions = new CastFunctions();
        address currentOwner = castFunctions.getOwner(arbitrageAddr);
        bool condition = (currentOwner == walletAddr) || (currentOwner == chromeWalletAddr);
        assertTrue(condition, "Invalid wallets for owner check");

        if (currentOwner == walletAddr) {
            (txHash, code) = castFunctions.setProfitAddress(chromeWalletAddr, arbitrageAddr, walletAddr, walletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set profit address");
            address updatedProfitAddress = castFunctions.getProfitAddress(arbitrageAddr);
            assertEq(updatedProfitAddress, chromeWalletAddr, "Profit address should be updated to chrome wallet address");
        } else if (currentOwner == chromeWalletAddr) {
            (txHash, code) = castFunctions.setProfitAddress(walletAddr, arbitrageAddr, chromeWalletAddr, chromeWalletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set profit address");
            address updatedProfitAddress = castFunctions.getProfitAddress(arbitrageAddr);
            assertEq(updatedProfitAddress, walletAddr, "Profit address should be updated to chrome wallet address");
        }
    }

    function test_setFlashLoanAddress() public {
        CastFunctions castFunctions = new CastFunctions();
        address currentOwner = castFunctions.getOwner(arbitrageAddr);
        bool condition = (currentOwner == walletAddr) || (currentOwner == chromeWalletAddr);
        assertTrue(condition, "Invalid wallets for owner check");

        string memory currentPrivateKeyStr;
        if (currentOwner == walletAddr) {
            currentPrivateKeyStr = walletPrivateKeyStr;
        } else if (currentOwner == chromeWalletAddr) {
            currentPrivateKeyStr = chromeWalletPrivateKeyStr;
        }

        address currentFlashLoanAddr = castFunctions.getFlashLoanAddress(arbitrageAddr);
        address newFlashLoanAddr;

        if (currentFlashLoanAddr == flashLoanAddr1) {
            newFlashLoanAddr = flashLoanAddr2;
        } else if (currentFlashLoanAddr == flashLoanAddr2) {
            newFlashLoanAddr = flashLoanAddr1;
        } else {
            newFlashLoanAddr = flashLoanAddr2;
        }
        (txHash, code) = castFunctions.setFlashLoanAddress(arbitrageAddr, newFlashLoanAddr, currentOwner, currentPrivateKeyStr);
        console.log("Code:");
        console.log(code);
        if (code == 1) {
            console.log("Code is int 1");
        }
        assertEq(code, 1, "Failed to set flash loan address");
        address updatedFlashLoanAddress = castFunctions.getFlashLoanAddress(arbitrageAddr);
        assertEq(updatedFlashLoanAddress, newFlashLoanAddr, "Flash loan address should be updated to new flash loan address");
        /*
        if (currentOwner == walletAddr) {
            (txHash, code) = castFunctions.setFlashLoanAddress(arbitrageAddr, testFlashLoanAddr, walletAddr, walletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set flash loan address");
            address updatedFlashLoanAddress = castFunctions.getFlashLoanAddress(arbitrageAddr);
            assertEq(updatedFlashLoanAddress, testFlashLoanAddr, "Flash loan address should be updated to test flash loan address");
        } else if (currentOwner == chromeWalletAddr) {
            (txHash, code) =
                castFunctions.setFlashLoanAddress(arbitrageAddr, testFlashLoanAddr, chromeWalletAddr, chromeWalletPrivateKeyStr);
            console.log("Code:");
            console.log(code);
            if (code == 1) {
                console.log("Code is int 1");
            }
            assertEq(code, 1, "Failed to set flash loan address");
            address updatedFlashLoanAddress = castFunctions.getFlashLoanAddress(arbitrageAddr);
            assertEq(updatedFlashLoanAddress, testFlashLoanAddr, "Flash loan address should be updated to test flash loan address");
        }
        */
    }

    function test_executeArbitrage() public {
        uint256 minProfit = 0; // Minimum profit set to 0 for this test
        uint256 fee = 0; // No fee for mock testing
        CastFunctions castFunctions = new CastFunctions();

        address currentOwner = castFunctions.getOwner(arbitrageAddr);
        bool isAuthorized = (currentOwner == walletAddr) || (currentOwner == chromeWalletAddr);
        assertTrue(isAuthorized, "Owner must be a trusted wallet");

        // Snapshot initial balances
        uint256 initialArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 initialWalletEth = castFunctions.addressBalance(walletAddr);
        uint256 initialDex1Pfx = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        uint256 initialDex2Pfx = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);

        console.log("Initial Arbitrage Contract ETH:", initialArbEth);
        console.log("Initial Wallet ETH:", initialWalletEth);
        console.log("Initial DEX1 Pigfox:", initialDex1Pfx);
        console.log("Initial DEX2 Pigfox:", initialDex2Pfx);

        // Check arbitrage opportunity
        uint256 dex1Price = castFunctions.getTokenPrice(dex1Addr, pigfoxTokenAddr);
        uint256 dex2Price = castFunctions.getTokenPrice(dex2Addr, pigfoxTokenAddr);

        console.log("DEX1 Price (wei per PFX):", dex1Price);
        console.log("DEX2 Price (wei per PFX):", dex2Price);

        require(dex2Price < dex1Price, "No arbitrage opportunity: DEX2 price must be lower than DEX1 price");

        uint256 tradeAmount = TRADE_AMOUNT; // Amount of Pigfox tokens to trade
        uint256 ethToBorrow = VAULT_ETH_FUNDING; // Amount of ETH to borrow for flash loan

        // Encode flash loan data
        bytes memory data = abi.encode(pigfoxTokenAddr, dex2Addr, dex1Addr, tradeAmount, minProfit);

        // Execute flash loan and arbitrage
        castFunctions.flashLoan(arbitrageAddr, pigfoxTokenAddr, ethToBorrow, fee, data);

        // Snapshot final balances
        uint256 finalArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 finalWalletEth = castFunctions.addressBalance(walletAddr);

        console.log("Final Arbitrage Contract ETH:", finalArbEth);
        console.log("Final Wallet ETH:", finalWalletEth);

        // Calculate profit
        require(finalWalletEth > initialWalletEth, "Expected final wallet ETH > initial wallet ETH");

        uint256 profit = finalWalletEth - initialWalletEth;
        console.log("Profit (wei):", profit);

        assertGt(profit, 0, "Arbitrage did not generate a profit");
    }
}
