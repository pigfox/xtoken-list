// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {PigfoxToken} from "../src/PigfoxToken.sol";
import {IDex} from "../src/IDex.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract CastFunctions is Test {
    using stdJson for string;
    ConversionsTest public conversionsTest;
    string public rpcUrl;
    string public walletAddr;
    string public privateKey;

    event GetTokenBalanceOfEvent(address indexed tokenAddress, address indexed holderAddress, uint256 balance);
    event MintEvent(address indexed tokenAddress, uint256 amount, string txHash);
    event DepositTokensEvent(address indexed dexAddress, address indexed tokenAddress, uint256 amount, string txHash);
    event ApproveEvent(address indexed tokenAddress, address indexed spenderAddress, uint256 amount, string txHash);
    event BalanceEvent(address indexed contractAddress, uint256 balance);
    event SetTokenPriceEvent(address indexed dexAddress, address indexed tokenAddress, uint256 price, string txHash);
    event WithdrawTokensEvent(address indexed dexAddress, address indexed tokenAddress, uint256 amount, string txHash);

    constructor() {
        conversionsTest = new ConversionsTest();
        rpcUrl = vm.envString("SEPOLIA_HTTP_RPC_URL");
        walletAddr = vm.toString(vm.envAddress("WALLET_ADDRESS"));
        privateKey = vm.envString("PRIVATE_KEY");
    }

    function addressBalance(string calldata _contractAddress) public returns (uint256) {
        address addr = conversionsTest.stringToAddress(_contractAddress);
        uint256 balance = addr.balance;
        emit BalanceEvent(addr, balance);
        return balance;
    }

    function getTokenBalanceOf(string calldata _holderAddress, string calldata _tokenAddress) public returns (uint256) {
        PigfoxToken token = PigfoxToken(conversionsTest.stringToAddress(_tokenAddress));
        address holder = conversionsTest.stringToAddress(_holderAddress);
        uint256 balance = token.balanceOf(holder);
        emit GetTokenBalanceOfEvent(address(token), holder, balance); // Fixed: Convert PigfoxToken to address
        return balance;
    }

    function mint(string calldata _tokenAddress, uint256 _amount) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _tokenAddress,
            " \"mint(uint256)\" ",
            vm.toString(_amount),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("Mint command (execute externally):", cmd);
        string memory txHash = "0x_simulated_mint_tx";
        string memory status = "0x1";
        emit MintEvent(conversionsTest.stringToAddress(_tokenAddress), _amount, txHash);
        return (txHash, status);
    }

    function approve(string calldata _tokenAddress, string calldata _spenderAddress, uint256 _amount) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _tokenAddress,
            " \"approve(address,uint256)\" ",
            _spenderAddress,
            " ",
            vm.toString(_amount),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("Approve command (execute externally):", cmd);
        string memory txHash = "0x_simulated_approve_tx";
        string memory status = "0x1";
        emit ApproveEvent(conversionsTest.stringToAddress(_tokenAddress), conversionsTest.stringToAddress(_spenderAddress), _amount, txHash);
        return (txHash, status);
    }

    function depositTokens(string calldata _dex, string calldata _token, uint256 _amount) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _token,
            " \"transfer(address,uint256)\" ",
            _dex,
            " ",
            vm.toString(_amount),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("Deposit command (execute externally):", cmd);
        string memory txHash = "0x_simulated_deposit_tx";
        string memory status = "0x1";
        emit DepositTokensEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_token), _amount, txHash);
        return (txHash, status);
    }

    function withdrawTokens(string calldata _dex, string calldata _token, uint256 _amount) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _dex,
            " \"withdraw(address,uint256)\" ",
            _token,
            " ",
            vm.toString(_amount),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("Withdraw command (execute externally):", cmd);
        string memory txHash = "0x_simulated_withdraw_tx";
        string memory status = "0x1";
        emit WithdrawTokensEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_token), _amount, txHash);
        return (txHash, status);
    }

    function setTokenPrice(string calldata _dex, string calldata _tokenAddress, uint256 _price) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _dex,
            " \"setTokenPrice(address,uint256)\" ",
            _tokenAddress,
            " ",
            vm.toString(_price),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("Set price command (execute externally):", cmd);
        string memory txHash = "0x_simulated_setprice_tx";
        string memory status = "0x1";
        emit SetTokenPriceEvent(conversionsTest.stringToAddress(_dex), conversionsTest.stringToAddress(_tokenAddress), _price, txHash);
        return (txHash, status);
    }

    function getTokenPrice(string calldata _dex, string calldata _tokenAddress) public returns (uint256) {
        IDex dex = IDex(conversionsTest.stringToAddress(_dex));
        uint256 price = dex.getTokenPrice(conversionsTest.stringToAddress(_tokenAddress));
        return price;
    }

    function fundEth(string calldata _to, uint256 _amount) public returns (string memory, string memory) {
        string memory cmd = string.concat(
            "cast send ",
            _to,
            " --value ",
            vm.toString(_amount),
            " --rpc-url ",
            rpcUrl,
            " --from ",
            walletAddr,
            " --private-key ",
            privateKey,
            " --json"
        );
        console.log("ETH funding command (execute externally):", cmd);
        string memory txHash = "0x_simulated_fund_tx";
        string memory status = "0x1";
        return (txHash, status);
    }
}