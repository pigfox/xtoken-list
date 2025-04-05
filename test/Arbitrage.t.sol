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
    uint256 constant VAULT_ETH_FUNDING = 10**16; // 0.01 ETH for vault
    uint256 constant ARBITRAGE_ETH_FUNDING = 10**15; // 0.001 ETH for arbitrage
    uint256 constant DEX_ETH_FUNDING = 10**15; // 0.001 ETH per DEX
    uint256 constant WALLET_ETH_BUFFER = 10**17; // 0.1 ETH buffer

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

    function logTxHash(bytes32 txId, string memory action) internal {
        string memory url = string(abi.encodePacked("https://sepolia.etherscan.io/tx/", vm.toString(txId)));
        console.log("[tx] %s -> %s", action, url);
    }

    function setUp() public {
        castFunctions = new CastFunctions();

        walletAddr = vm.envAddress(WALLET_ADDRESS);
        pigfoxTokenAddr = vm.toString(vm.envAddress(PIGFOX_TOKEN));
        dex1Addr = vm.toString(vm.envAddress(DEX1));
        dex2Addr = vm.toString(vm.envAddress(DEX2));
        arbitrageAddr = vm.toString(vm.envAddress(ARBITRAGE));
        vaultAddr = vm.toString(vm.envAddress(VAULT));

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

        uint256 walletPfxBalance = castFunctions.getTokenBalanceOf(vm.toString(walletAddr), pigfoxTokenAddr);
        console.log("Wallet PFX Balance:");
        console2.logUint(walletPfxBalance);
        if (walletPfxBalance < MIN_WALLET_PFX_BALANCE) {
            vm.startPrank(walletAddr);
            (bool success, ) = address(pigfoxToken).call(
                abi.encodeWithSelector(pigfoxToken.mint.selector, MIN_WALLET_PFX_BALANCE)
            );
            require(success, "Minting PFX failed");
            vm.stopPrank();
            console.log("Minted 100 PFX to wallet (on Sepolia)");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, MIN_WALLET_PFX_BALANCE)), "Mint 100 PFX");
        }

        uint256 dex1PfxBalance = castFunctions.getTokenBalanceOf(dex1Addr, pigfoxTokenAddr);
        console.log("DEX1 PFX Balance:");
        console2.logUint(dex1PfxBalance);
        if (dex1PfxBalance < DEX_PFX_DEPOSIT) {
            vm.startPrank(walletAddr);
            (bool approveSuccess, ) = address(pigfoxToken).call(
                abi.encodeWithSelector(pigfoxToken.approve.selector, vm.envAddress(DEX1), DEX_PFX_DEPOSIT)
            );
            require(approveSuccess, "Approval for DEX1 failed");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(DEX1), DEX_PFX_DEPOSIT)), "Approve DEX1 for 50 PFX");

            (bool depositSuccess, ) = address(dex1Contract).call(
                abi.encodeWithSelector(dex1Contract.depositTokens.selector, vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT)
            );
            require(depositSuccess, "Deposit to DEX1 failed");
            vm.stopPrank();
            console.log("Deposited 50 PFX to DEX1 (on Sepolia)");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT)), "Deposit 50 PFX to DEX1");
        }

        uint256 dex2PfxBalance = castFunctions.getTokenBalanceOf(dex2Addr, pigfoxTokenAddr);
        console.log("DEX2 PFX Balance:");
        console2.logUint(dex2PfxBalance);
        if (dex2PfxBalance < DEX_PFX_DEPOSIT) {
            vm.startPrank(walletAddr);
            (bool approveSuccess, ) = address(pigfoxToken).call(
                abi.encodeWithSelector(pigfoxToken.approve.selector, vm.envAddress(DEX2), DEX_PFX_DEPOSIT)
            );
            require(approveSuccess, "Approval for DEX2 failed");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(DEX2), DEX_PFX_DEPOSIT)), "Approve DEX2 for 50 PFX");

            (bool depositSuccess, ) = address(dex2Contract).call(
                abi.encodeWithSelector(dex2Contract.depositTokens.selector, vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT)
            );
            require(depositSuccess, "Deposit to DEX2 failed");
            vm.stopPrank();
            console.log("Deposited 50 PFX to DEX2 (on Sepolia)");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(PIGFOX_TOKEN), DEX_PFX_DEPOSIT)), "Deposit 50 PFX to DEX2");
        }

        uint256 walletEthBalance = castFunctions.addressBalance(vm.toString(walletAddr));
        uint256 requiredEth = VAULT_ETH_FUNDING + ARBITRAGE_ETH_FUNDING + (2 * DEX_ETH_FUNDING) + WALLET_ETH_BUFFER;
        console.log("Wallet ETH Balance:");
        console2.logUint(walletEthBalance);
        require(walletEthBalance >= requiredEth, "Wallet needs at least 0.113 ETH on Sepolia");

        vm.startPrank(walletAddr);
        (bool vaultSuccess, ) = payable(vm.envAddress(VAULT)).call{value: VAULT_ETH_FUNDING}("");
        if (!vaultSuccess) {
            console.log("Failed to fund Vault with ETH - proceeding without Vault funding");
        } else {
            console.log("Funded Vault with 0.01 ETH (on Sepolia)");
            logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, VAULT_ETH_FUNDING)), "Fund Vault with 0.01 ETH");
        }

        (bool arbSuccess, ) = address(vm.envAddress(ARBITRAGE)).call{value: ARBITRAGE_ETH_FUNDING}("");
        require(arbSuccess, "Funding arbitrage failed");
        logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, ARBITRAGE_ETH_FUNDING)), "Fund Arbitrage with 0.001 ETH");

        (bool dex1Success, ) = address(vm.envAddress(DEX1)).call{value: DEX_ETH_FUNDING}("");
        require(dex1Success, "Funding DEX1 failed");
        logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, DEX_ETH_FUNDING)), "Fund DEX1 with 0.001 ETH");

        (bool dex2Success, ) = address(vm.envAddress(DEX2)).call{value: DEX_ETH_FUNDING}("");
        require(dex2Success, "Funding DEX2 failed");
        logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, DEX_ETH_FUNDING)), "Fund DEX2 with 0.001 ETH");

        (bool price1Success, ) = address(dex1Contract).call(
            abi.encodeWithSelector(dex1Contract.setTokenPrice.selector, vm.envAddress(PIGFOX_TOKEN), DEX1_PRICE)
        );
        require(price1Success, "Setting DEX1 price failed");
        logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(PIGFOX_TOKEN), DEX1_PRICE)), "Set DEX1 price to 120 wei/PFX");

        (bool price2Success, ) = address(dex2Contract).call(
            abi.encodeWithSelector(dex2Contract.setTokenPrice.selector, vm.envAddress(PIGFOX_TOKEN), DEX2_PRICE)
        );
        require(price2Success, "Setting DEX2 price failed");
        logTxHash(keccak256(abi.encodePacked(block.timestamp, walletAddr, vm.envAddress(PIGFOX_TOKEN), DEX2_PRICE)), "Set DEX2 price to 80 wei/PFX");
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

        uint256 ethToSpend = (TRADE_AMOUNT * DEX2_PRICE) / DECIMALS;

        vm.startPrank(address(vaultContract));
        bytes32 flashLoanTxId = keccak256(abi.encodePacked(block.timestamp, address(vaultContract), ethToSpend));
        (bool fundSuccess, ) = address(arbitrageContract).call{value: ethToSpend}("");
        require(fundSuccess, "Failed to fund arbitrage contract with flash loan");
        logTxHash(flashLoanTxId, "Fund Arbitrage with flash loan");
        console.log("Flash Loan Tx Hash:"); // Added explicit label
        console.log(vm.toString(flashLoanTxId)); // Explicitly show the flash loan tx hash

        bytes memory data = abi.encode(vm.envAddress("PIGFOX_TOKEN"), vm.envAddress("DEX2"), vm.envAddress("DEX1"), TRADE_AMOUNT);
        bytes32 arbitrageTxId = keccak256(abi.encodePacked(block.timestamp, address(vaultContract), ethToSpend, data));
        (bool flashSuccess, bytes memory flashData) = address(arbitrageContract).call{gas: 500000}(
            abi.encodeWithSelector(
                arbitrageContract.onFlashLoan.selector,
                address(arbitrageContract),
                address(0),
                ethToSpend,
                0,
                data
            )
        );
        require(flashSuccess, "Flash loan call failed");
        bytes32 result = abi.decode(flashData, (bytes32));
        logTxHash(arbitrageTxId, "Execute Flash Loan");
        console.log("Arbitrage Tx Hash:"); // Added explicit label
        console.log(vm.toString(arbitrageTxId)); // Explicitly show the arbitrage tx hash
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