// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/PigfoxToken.sol";
import "../src/IDex.sol";
import "../src/Arbitrage.sol";
import "../src/Vault.sol";
import "./CastFunctions.sol";

contract ArbitrageTest is Test {
    CastFunctions public castFunctions;
    address public walletAddr;

    string constant SEPOLIA_RPC_URL = "SEPOLIA_HTTP_RPC_URL";
    string constant WALLET_ADDRESS = "WALLET_ADDRESS";
    string constant PIGFOX_TOKEN = "PIGFOX_TOKEN";
    string constant DEX1 = "DEX1";
    string constant DEX2 = "DEX2";
    string constant ARBITRAGE = "ARBITRAGE";
    string constant VAULT = "VAULT";

    uint256 constant DECIMALS = 10**18;
    uint256 constant MIN_WALLET_PFX_BALANCE = 100 * DECIMALS;
    uint256 constant DEX_PFX_DEPOSIT = 50 * DECIMALS;
    uint256 constant TRADE_AMOUNT = 10 * DECIMALS;
    uint256 constant VAULT_ETH_FUNDING = 10 * DECIMALS;
    uint256 constant ARBITRAGE_ETH_FUNDING = 1 * DECIMALS;
    uint256 constant DEX_ETH_FUNDING = 1 * DECIMALS;
    uint256 constant WALLET_ETH_BUFFER = 2 * DECIMALS;

    uint256 constant DEX1_PRICE = 120; // wei/PFX
    uint256 constant DEX2_PRICE = 80;  // wei/PFX

    string pigfoxTokenAddr;
    string dex1Addr;
    string dex2Addr;
    string arbitrageAddr;
    string vaultAddr;

    IDex dex1Contract;
    IDex dex2Contract;
    Arbitrage arbitrageContract;
    Vault vaultContract;
    PigfoxToken pigfoxToken;

    function setUp() public {
        castFunctions = new CastFunctions();

        // Load environment variables
        walletAddr = vm.envAddress(WALLET_ADDRESS);
        pigfoxTokenAddr = vm.toString(vm.envAddress(PIGFOX_TOKEN));
        dex1Addr = vm.toString(vm.envAddress(DEX1));
        dex2Addr = vm.toString(vm.envAddress(DEX2));
        arbitrageAddr = vm.toString(vm.envAddress(ARBITRAGE));
        vaultAddr = vm.toString(vm.envAddress(VAULT));

        // Initialize contract interfaces
        pigfoxToken = PigfoxToken(vm.envAddress(PIGFOX_TOKEN));
        dex1Contract = IDex(vm.envAddress(DEX1));
        dex2Contract = IDex(vm.envAddress(DEX2));
        arbitrageContract = Arbitrage(payable(vm.envAddress(ARBITRAGE)));
        vaultContract = Vault(payable(vm.envAddress(VAULT)));

        console.log("Wallet Address:", walletAddr);
        console.log("PigfoxToken Address:", pigfoxTokenAddr);
        console.log("DEX1 Address:", dex1Addr);
        console.log("DEX2 Address:", dex2Addr);
        console.log("Arbitrage Address:", arbitrageAddr);
        console.log("Vault Address:", vaultAddr);

        // Check wallet PFX balance and mint if needed
        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(vm.toString(walletAddr), pigfoxTokenAddr);
        console.log("Wallet PFX Balance:");
        console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            vm.startPrank(walletAddr);
            pigfoxToken.mint(MIN_WALLET_PFX_BALANCE);
            vm.stopPrank();
            console.log("Minted 100 PFX to wallet (on Sepolia)");
        }

        // Deposit PFX to DEX1 if needed
        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            vm.startPrank(walletAddr);
            pigfoxToken.approve(vm.envAddress(DEX1), DEX_PFX_DEPOSIT);
            dex1Contract.depositTokens(vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT);
            vm.stopPrank();
            console.log("Deposited 50 PFX to DEX1 (on Sepolia)");
        }

        // Deposit PFX to DEX2 if needed
        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            vm.startPrank(walletAddr);
            pigfoxToken.approve(vm.envAddress(DEX2), DEX_PFX_DEPOSIT);
            dex2Contract.depositTokens(vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT);
            vm.stopPrank();
            console.log("Deposited 50 PFX to DEX2 (on Sepolia)");
        }

        // Check wallet ETH balance (assumes wallet already has ETH)
        uint256 walletEthBalance = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        console.log("Wallet ETH Balance:");
        console2.logUint(walletEthBalance);
        require(walletEthBalance >= requiredEth, "Wallet needs at least 15 ETH on Sepolia");

        // Fund contracts with ETH from wallet
        vm.startPrank(walletAddr);
        (bool vaultSuccess, ) = payable(vm.envAddress(VAULT)).call{value: VAULT_ETH_FUNDING}("");
        if (!vaultSuccess) {
            console.log("Failed to fund Vault with ETH - proceeding without Vault funding");
        } else {
            console.log("Funded Vault with 10 ETH (on Sepolia)");
        }
        payable(vm.envAddress(ARBITRAGE)).transfer(ARBITRAGE_ETH_FUNDING);
        payable(vm.envAddress(DEX1)).transfer(DEX_ETH_FUNDING);
        payable(vm.envAddress(DEX2)).transfer(DEX_ETH_FUNDING);
        vm.stopPrank();

        // Set DEX prices on-chain
        vm.startPrank(walletAddr);
        dex1Contract.setTokenPrice(vm.envAddress(PIGFOX_TOKEN), DEX1_PRICE);
        dex2Contract.setTokenPrice(vm.envAddress(PIGFOX_TOKEN), DEX2_PRICE);
        vm.stopPrank();

        console.log("Set DEX1 price to 120 wei/PFX (on Sepolia)");
        console.log("Set DEX2 price to 80 wei/PFX (on Sepolia)");
    }

    function test_executeArbitrage() public {
        uint256 initialArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 initialWalletEth = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 initialDex1Pfx = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        uint256 initialDex2Pfx = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("Initial Arbitrage ETH:");
        console2.logUint(initialArbEth);
        console.log("Initial Wallet ETH:");
        console2.logUint(initialWalletEth);
        console.log("Initial DEX1 PFX:");
        console2.logUint(initialDex1Pfx);
        console.log("Initial DEX2 PFX:");
        console2.logUint(initialDex2Pfx);

        uint256 dex1Price = castFunctions.getTokenPrice(dex1Addr, pigfoxTokenAddr);
        uint256 dex2Price = castFunctions.getTokenPrice(dex2Addr, pigfoxTokenAddr);
        console.log("DEX1 Price (wei/PFX):");
        console2.logUint(dex1Price);
        console.log("DEX2 Price (wei/PFX):");
        console2.logUint(dex2Price);
        require(dex2Price < dex1Price, "No arbitrage opportunity");

        // Calculate ETH needed for the trade
        uint256 ethToSpend = (TRADE_AMOUNT * DEX2_PRICE) / DECIMALS;

        // Simulate flash loan by funding the arbitrage contract from the vault
        vm.startPrank(address(vaultContract));
        (bool success, ) = address(arbitrageContract).call{value: ethToSpend}("");
        require(success, "Failed to fund arbitrage contract with flash loan");
        bytes memory data = abi.encode(vm.envAddress(PIGFOX_TOKEN), vm.envAddress(DEX2), vm.envAddress(DEX1), TRADE_AMOUNT);

        // Call onFlashLoan as the vault
        bytes32 result = arbitrageContract.onFlashLoan(
            address(arbitrageContract),
            address(0),
            ethToSpend,
            0, // No fee for simplicity
            data
        );
        vm.stopPrank();
        assertEq(result, keccak256("FlashLoanBorrower.onFlashLoan"), "Flash loan callback failed");

        uint256 finalArbEth = castFunctions.addressBalance(arbitrageAddr);
        uint256 finalWalletEth = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 finalDex1Pfx = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        uint256 finalDex2Pfx = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("Final Arbitrage ETH:");
        console2.logUint(finalArbEth);
        console.log("Final Wallet ETH:");
        console2.logUint(finalWalletEth);
        console.log("Final DEX1 PFX:");
        console2.logUint(finalDex1Pfx);
        console.log("Final DEX2 PFX:");
        console2.logUint(finalDex2Pfx);

        // Profit goes to profitAddress (wallet in this case)
        uint256 profit = finalWalletEth - initialWalletEth;
        assertGt(profit, 0, "No profit made");
        console.log("Profit (ETH wei):");
        console2.logUint(profit);

        uint256 expectedDex2Pfx = initialDex2Pfx - TRADE_AMOUNT;
        uint256 expectedDex1Pfx = initialDex1Pfx + TRADE_AMOUNT;
        assertEq(finalDex2Pfx, expectedDex2Pfx, "DEX2 balance incorrect");
        assertEq(finalDex1Pfx, expectedDex1Pfx, "DEX1 balance incorrect");
    }
}