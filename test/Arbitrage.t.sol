// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "./CastFunctions.sol";

contract ArbitrageTest is Test {
    CastFunctions public castFunctions;
    string private txHash;
    uint256 private code;

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

    address private pigfoxTokenAddr;
    address private dex1Addr;
    address private dex2Addr;
    address private arbitrageAddr;
    address private vaultAddr;
    address private walletAddr;
    address private chromeWalletAddr;
    string private walletPrivateKeyStr;
    string private chromeWalletPrivateKeyStr;

    function logTxHash(string memory _txHash, string memory _action) internal view {
        string memory url = string(abi.encodePacked("https://sepolia.etherscan.io/tx/", _txHash));
        console.log("[tx] %s -> %s", _action, url);
    }

    function setUp() public {
        castFunctions = new CastFunctions();

        walletAddr = vm.envAddress("WALLET_ADDRESS");
        walletPrivateKeyStr = vm.envString("WALLET_PRIVATE_KEY");
        chromeWalletAddr = vm.envAddress("CHROME_WALLET");
        chromeWalletPrivateKeyStr = vm.envString("CHROME_WALLET_PRIVATE_KEY");
        pigfoxTokenAddr = vm.envAddress("PIGFOX_TOKEN");
        dex1Addr = vm.envAddress("DEX1");
        dex2Addr = vm.envAddress("DEX2");
        arbitrageAddr = vm.envAddress("ARBITRAGE");
        vaultAddr = vm.envAddress("VAULT");
        /*
        console.log("Wallet Address:", walletAddr);
        console.log("Chrome Wallet Address:", chromeWalletAddr);
        console.log("PigfoxToken Address:", pigfoxTokenAddr);
        console.log("DEX1 Address:", dex1Addr);
        console.log("DEX2 Address:", dex2Addr);
        console.log("Arbitrage Address:", arbitrageAddr);
        console.log("Vault Address:", vaultAddr);
        */
        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(walletAddr, pigfoxTokenAddr);
        console.log("Wallet PFX Balance:");
        console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            //pigfoxToken.mint(MIN_WALLET_PFX_BALANCE);
            (txHash, code) = castFunctions.mint(pigfoxTokenAddr, MIN_WALLET_PFX_BALANCE);
            if (code == 1) {
                logTxHash(
                    txHash, string.concat("Minted ", vm.toString(MIN_WALLET_PFX_BALANCE), " PFX to wallet (on Sepolia)")
                );
            }
        }

        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            castFunctions.approve(pigfoxTokenAddr, walletAddr, ARBITRAGE_ETH_FUNDING);
            (txHash, code) = castFunctions.depositTokens(dex1Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            if (code == 1) {
                logTxHash(
                    txHash, string.concat("Deposited ", vm.toString(DEX_PFX_DEPOSIT), " PFX to DEX1 (on Sepolia)")
                );
            }
        }

        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            castFunctions.approve(pigfoxTokenAddr, walletAddr, ARBITRAGE_ETH_FUNDING);
            (txHash, code) = castFunctions.depositTokens(dex2Addr, pigfoxTokenAddr, DEX_PFX_DEPOSIT);
            if (code == 1) {
                logTxHash(
                    txHash, string.concat("Deposited ", vm.toString(DEX_PFX_DEPOSIT), " PFX to DEX2 (on Sepolia)")
                );
            }
        }

        uint256 walletEthBalance = castFunctions.addressBalance(walletAddr);
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        console.log("Wallet ETH Balance:");
        console2.logUint(walletEthBalance);
        require(walletEthBalance >= requiredEth, "Wallet needs at least 0.113 ETH on Sepolia");

        (txHash, code) = castFunctions.fundEth(vaultAddr, VAULT_ETH_FUNDING);
        if (code == 1) {
            console.log(string.concat("Funded Vault with ", vm.toString(VAULT_ETH_FUNDING), " ETH (on Sepolia)"));
        } else {
            console.log(
                string.concat(
                    "Failed to fund Vault with ",
                    vm.toString(VAULT_ETH_FUNDING),
                    " ETH - proceeding without Vault funding"
                )
            );
        }

        (txHash, code) = castFunctions.setTokenPrice(dex1Addr, pigfoxTokenAddr, DEX1_PRICE);
        (txHash, code) = castFunctions.setTokenPrice(dex2Addr, pigfoxTokenAddr, DEX2_PRICE);
    }

    function test_setProfitAddress() public {
        (txHash, code) =
            castFunctions.setProfitAddress(chromeWalletAddr, arbitrageAddr, walletAddr, walletPrivateKeyStr);
        if (code == 1) {
            console.log("Profit address set:");
        } else {
            console.log("Profit address failed:");
        }

        address updatedProfitAddress = castFunctions.getProfitAddress(arbitrageAddr);
        assertEq(updatedProfitAddress, chromeWalletAddr, "Profit address should be updated to chrome wallet address");
    }
    /*
    function test_executeArbitrage() public {
        vm.startBroadcast(walletPrivateKey);

        // Initial balances
        uint256 initialArbEth = address(arbitrageContract).balance;
        uint256 initialWalletEth = walletAddr.balance;
        uint256 initialDex1Pfx = pigfoxToken.balanceOf(address(dex1Contract));
        uint256 initialDex2Pfx = pigfoxToken.balanceOf(address(dex2Contract));
        console.log("Initial Arbitrage ETH:", initialArbEth);
        console.log("Initial Wallet ETH:", initialWalletEth);
        console.log("Initial DEX1 PFX:", initialDex1Pfx);
        console.log("Initial DEX2 PFX:", initialDex2Pfx);

        // Check prices
        uint256 dex1Price = dex1Contract.getTokenPrice(address(pigfoxToken));
        uint256 dex2Price = dex2Contract.getTokenPrice(address(pigfoxToken));
        console.log("DEX1 Price (wei/PFX):", dex1Price);
        console.log("DEX2 Price (wei/PFX):", dex2Price);
        require(dex2Price < dex1Price, "No arbitrage opportunity");

        // Flash loan amount
        uint256 tradeAmount = TRADE_AMOUNT; // 10 PFX
        uint256 ethToBorrow = VAULT_ETH_FUNDING; // Borrow 0.01 ETH

        ---
        So minProfit should be computed off-chain by your bot or script that detects arbitrage opportunities and triggers the contract. It looks at:

        Prices on both DEXs

        Flash loan fee

        Expected slippage

        Gas cost estimate
        ----

        // Prepare flash loan data
        bytes memory data = abi.encode(pigfoxTokenAddrStr, dex2AddrStr, dex1AddrStr, tradeAmount, minProfit);

        // Execute flash loan
        vaultContract.flashLoan(address(arbitrageContract), address(0), ethToBorrow, data);

        // Final balances
        uint256 finalArbEth = address(arbitrageContract).balance;
        uint256 finalWalletEth = walletAddr.balance;
        console.log("Final Arbitrage ETH:", finalArbEth);
        console.log("Final Wallet ETH:", finalWalletEth);

        // Verify profit
        uint256 profit = finalWalletEth - initialWalletEth;
        assertGt(profit, 0, "No profit made");
        console.log("Profit (ETH wei):", profit);

    }
    */
}
