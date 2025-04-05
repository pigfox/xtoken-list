// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IDex.sol";

interface IFlashLoanProvider {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external;
}

contract Arbitrage is ReentrancyGuard {
    address public owner;
    address public profitAddress;
    IFlashLoanProvider public immutable flashLoanProvider;

    uint256 public constant DECIMALS = 10**18;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ProfitAddressChanged(address indexed oldProfitAddress, address indexed newProfitAddress);
    event ApproveToken(address indexed token, address indexed dex, uint256 amount);
    event WithdrawTokens(address indexed token, uint256 amount);
    event WithdrawETH(address indexed to, uint256 amount);
    event TransactionExecuted(bytes32 indexed txId, string action);
    event FlashLoanInitiated(address indexed token, uint256 amount);
    event ArbitrageExecuted(uint256 profit);

    constructor(address _flashLoanProvider) {
        owner = msg.sender;
        profitAddress = msg.sender;
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Invalid owner address");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _owner));
        emit OwnerChanged(owner, _owner);
        emit TransactionExecuted(txId, "SetOwner");
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setProfitAddress(address _profitAddress) external onlyOwner {
        require(_profitAddress != address(0), "Invalid profit address");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _profitAddress));
        emit ProfitAddressChanged(profitAddress, _profitAddress);
        emit TransactionExecuted(txId, "SetProfitAddress");
        profitAddress = _profitAddress;
    }

    function _approveToken(address token, address dex, uint256 amount) internal {
        require(IERC20(token).approve(dex, amount), "Token approval failed");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, dex, amount));
        emit ApproveToken(token, dex, amount);
        emit TransactionExecuted(txId, "ApproveToken");
    }

    function run(
        address token,
        address dexCheap,
        address dexExpensive,
        uint256 amount,
        uint256 deadlineBlock
    ) external onlyOwner nonReentrant {
        require(block.number <= deadlineBlock, "Transaction deadline exceeded");

        uint256 priceCheap = IDex(dexCheap).getTokenPrice(token);
        uint256 priceExpensive = IDex(dexExpensive).getTokenPrice(token);
        require(priceCheap < priceExpensive, "No arbitrage opportunity");

        uint256 ethToSpend = (amount * priceCheap) / DECIMALS;

        bytes memory data = abi.encode(token, dexCheap, dexExpensive, amount);
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, ethToSpend, data));
        emit FlashLoanInitiated(address(0), ethToSpend);
        emit TransactionExecuted(txId, "RunFlashLoan");
        flashLoanProvider.flashLoan(address(this), address(0), ethToSpend, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external nonReentrant returns (bytes32) {
        require(msg.sender == address(flashLoanProvider), "Untrusted caller");
        require(initiator == address(this), "Invalid initiator");
        require(token == address(0), "Only ETH flash loans supported");

        (address tokenToTrade, address dexCheap, address dexExpensive, uint256 amountToTrade) =
                            abi.decode(data, (address, address, address, uint256));

        uint256 tokensBought = IDex(dexCheap).buyTokens{value: amount}(tokenToTrade, amountToTrade);
        require(tokensBought >= amountToTrade, "Failed to buy enough tokens");

        _approveToken(tokenToTrade, dexExpensive, tokensBought);

        uint256 ethReceived = IDex(dexExpensive).sellTokens(tokenToTrade, tokensBought);

        uint256 totalRepayment = amount + fee;
        require(ethReceived >= totalRepayment, "Arbitrage not profitable");
        uint256 profit = ethReceived - totalRepayment;

        (bool sentRepayment, ) = address(flashLoanProvider).call{value: totalRepayment}("");
        require(sentRepayment, "Loan repayment failed");

        if (profit > 0) {
            (bool sentProfit, ) = profitAddress.call{value: profit}("");
            require(sentProfit, "Profit transfer failed");
        }

        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, amount, fee, data));
        emit ArbitrageExecuted(profit);
        emit TransactionExecuted(txId, "OnFlashLoan");

        return keccak256("FlashLoanBorrower.onFlashLoan");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner nonReentrant {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, token, amount));
        emit WithdrawTokens(token, amount);
        emit TransactionExecuted(txId, "WithdrawTokens");
    }

    function withdrawETH(uint256 amount) external onlyOwner nonReentrant {
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
        bytes32 txId = keccak256(abi.encodePacked(block.timestamp, msg.sender, amount));
        emit WithdrawETH(owner, amount);
        emit TransactionExecuted(txId, "WithdrawETH");
    }

    receive() external payable {
        // Simplified to fit within 2300 gas stipend of deployed DEX contracts
    }
}