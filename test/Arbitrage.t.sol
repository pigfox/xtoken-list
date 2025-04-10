// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/PigfoxToken.sol";
import "../src/Dex.sol";
import "../src/Arbitrage.sol";
import "../src/Vault.sol";
import "./CastFunctions.sol";

contract ArbitrageTest is Test {
    CastFunctions public castFunctions;

    string constant SEPOLIA_HTTP_RPC_URL = "SEPOLIA_HTTP_RPC_URL";
    string constant WALLET_ADDRESS = "WALLET_ADDRESS";
    string constant WALLET_PRIVATE_KEY = "WALLET_PRIVATE_KEY";
    string constant CHROME_WALLET = "CHROME_WALLET";
    string constant CHROME_WALLET_PRIVATE_KEY = "CHROME_WALLET_PRIVATE_KEY";
    string constant PIGFOX_TOKEN = "PIGFOX_TOKEN";
    string constant DEX1 = "DEX1";
    string constant DEX2 = "DEX2";
    string constant ARBITRAGE = "ARBITRAGE";
    string constant VAULT = "VAULT";

    uint256 constant DECIMALS = 10**18;
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS;
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;
    uint256 constant VAULT_ETH_FUNDING = 10**16; // 0.01 ETH for vault
    uint256 constant ARBITRAGE_ETH_FUNDING = 10**15; // 0.001 ETH for arbitrage
    uint256 constant DEX_ETH_FUNDING = 10**15; // 0.001 ETH per DEX
    uint256 constant WALLET_ETH_BUFFER = 10**17; // 0.1 ETH buffer

    uint256 constant DEX1_PRICE = 120; // wei/PFX
    uint256 constant DEX2_PRICE = 80;  // wei/PFX

    address pigfoxTokenAddr;
    address payable dex1Addr;
    address payable dex2Addr;
    address payable arbitrageAddr;
    address payable vaultAddr;

    address walletAddr;
    uint256 walletPrivateKey;

    address chromeWalletAddr;
    uint256 chromeWalletPrivateKey;

    Dex dex1Contract;
    Dex dex2Contract;
    Arbitrage arbitrageContract;
    Vault vaultContract;
    PigfoxToken pigfoxToken;

    function logTxHash(bytes32 txId, string memory action) internal view {
        string memory url = string(abi.encodePacked("https://sepolia.etherscan.io/tx/", vm.toString(txId)));
        console.log("[tx] %s -> %s", action, url);
    }

    function setUp() public {
        castFunctions = new CastFunctions();

        walletAddr = vm.envAddress(WALLET_ADDRESS);
        walletPrivateKey = vm.envUint(WALLET_PRIVATE_KEY);
        chromeWalletAddr = vm.envAddress(CHROME_WALLET);
        chromeWalletPrivateKey = vm.envUint(CHROME_WALLET_PRIVATE_KEY);
        pigfoxTokenAddr = vm.envAddress(PIGFOX_TOKEN);
        dex1Addr = payable(vm.envAddress(DEX1));
        dex2Addr = payable(vm.envAddress(DEX2));
        arbitrageAddr = payable(vm.envAddress(ARBITRAGE));
        vaultAddr = payable(vm.envAddress(VAULT));

        pigfoxToken = PigfoxToken(vm.envAddress(PIGFOX_TOKEN));
        dex1Contract = Dex(dex1Addr);
        dex2Contract = Dex(dex2Addr);
        arbitrageContract = Arbitrage(arbitrageAddr);
        vaultContract = Vault(vaultAddr);

        console.log("Wallet Address:", walletAddr);
        console.log("Chrome Wallet Address:", chromeWalletAddr);
        console.log("PigfoxToken Address:", pigfoxTokenAddr);
        console.log("DEX1 Address:", dex1Addr);
        console.log("DEX2 Address:", dex2Addr);
        console.log("Arbitrage Address:", arbitrageAddr);
        console.log("Vault Address:", vaultAddr);

        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(vm.toString(walletAddr), vm.toString(pigfoxTokenAddr));
        console.log("Wallet PFX Balance:");
        console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            pigfoxToken.mint(MIN_WALLET_PFX_BALANCE);
            console.log("Minted 100 PFX to wallet (on Sepolia)");
        }

        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(vm.toString(dex1Addr), vm.toString(pigfoxTokenAddr));
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            castFunctions.approve(vm.toString(pigfoxTokenAddr), vm.toString(walletAddr), ARBITRAGE_ETH_FUNDING);
            dex1Contract.depositTokens(vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT);
            console.log("Deposited 50 PFX to DEX1 (on Sepolia)");
        }

        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(vm.toString(dex2Addr), vm.toString(pigfoxTokenAddr));
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            pigfoxToken.approve(vm.envAddress(DEX2), DEX_PFX_DEPOSIT);
            dex2Contract.depositTokens(vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT);
            console.log("Deposited 50 PFX to DEX2 (on Sepolia)");
        }

        uint256 walletEthBalance = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        console.log("Wallet ETH Balance:");
        console2.logUint(walletEthBalance);
        require(walletEthBalance >= requiredEth, "Wallet needs at least 0.113 ETH on Sepolia");

        (bool vaultSuccess, ) = payable(vm.envAddress(VAULT)).call{value: VAULT_ETH_FUNDING}("");
        if (!vaultSuccess) {
            console.log("Failed to fund Vault with ETH - proceeding without Vault funding");
        } else {
            console.log("Funded Vault with 0.01 ETH (on Sepolia)");
        }

        (bool arbSuccess, ) = payable(vm.envAddress(ARBITRAGE)).call{value: ARBITRAGE_ETH_FUNDING}("");
        require(arbSuccess, "Funding arbitrage failed");

        (bool dex1Success, ) = payable(vm.envAddress(DEX1)).call{value: DEX_ETH_FUNDING}("");
        require(dex1Success, "Funding DEX1 failed");

        (bool dex2Success, ) = payable(vm.envAddress(DEX2)).call{value: DEX_ETH_FUNDING}("");
        require(dex2Success, "Funding DEX2 failed");

        dex1Contract.setTokenPrice(vm.envAddress(PIGFOX_TOKEN), DEX1_PRICE);
        dex2Contract.setTokenPrice(vm.envAddress(PIGFOX_TOKEN), DEX2_PRICE);
    }

    function test_setProfitAddress()public{
        address initialProfitAddress = castFunctions.getProfitAddress(vm.toString(arbitrageAddr));
        assertEq(initialProfitAddress, walletAddr, "Initial profit address should be wallet address");

        (string memory txHash, string memory result) = castFunctions.setProfitAddress(chromeWalletAddr, arbitrageAddr, walletAddr, walletPrivateKey);
        console.log("Transaction Hash:", txHash);
        console.log("Result:", result);
        address updatedProfitAddress = castFunctions.getProfitAddress(vm.toString(arbitrageAddr));
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

        // Prepare flash loan data
        bytes memory data = abi.encode(address(pigfoxToken), address(dex2Contract), address(dex1Contract), tradeAmount);

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

        vm.stopBroadcast();
    }
    */
}