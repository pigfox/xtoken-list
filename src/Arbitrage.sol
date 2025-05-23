// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Arbitrage is ReentrancyGuard {
    address public flashLoanAddress;
    address public profitAddress;
    address public owner;
    uint256 public deadLine;

    // Events for debugging and monitoring
    event FlashLoanReceived(address indexed sender, address indexed initiator, uint256 amount, uint256 fee);
    event ArbitrageStep(address indexed dex, address indexed token, uint256 amountIn, uint256 amountOut);
    event LoanRepaid(address indexed lender, uint256 amount);
    event ProfitSent(address indexed recipient, uint256 amount);
    event UpdatedOwner(address indexed newOwner);
    event UpdatedProfitAddress(address indexed newProfitAddress);
    event UpdatedFlashLoanAddress(address indexed newFlashLoanAddress);
    event UpdatedDeadline(uint256 newDeadline);
    event SwapFailed(address indexed dex, address indexed token, string reason);

    constructor(address _flashLoanAddress) {
        require(_flashLoanAddress != address(0), "Invalid flash loan provider");
        flashLoanAddress = _flashLoanAddress;
        profitAddress = msg.sender;
        owner = msg.sender;
        deadLine = 60; // Set deadline to 1 minute from now
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Invalid new owner");
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setProfitAddress(address _profitAddress) external onlyOwner {
        require(_profitAddress != address(0), "Invalid profit address");
        profitAddress = _profitAddress;
        emit UpdatedProfitAddress(_profitAddress);
    }

    function setFlashLoanAddress(address _flashLoanAddress) external onlyOwner {
        require(_flashLoanAddress != address(0), "Invalid flashLoan address");
        flashLoanAddress = _flashLoanAddress;
        emit UpdatedFlashLoanAddress(_flashLoanAddress);
    }

    function setDeadline(uint256 _deadline) external onlyOwner {
        require(_deadline > 0, "Invalid deadline");
        deadLine = _deadline;
        emit UpdatedDeadline(_deadline);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    )
        external
        onlyOwner
        nonReentrant
        returns (bytes32)
    {
        // Validate caller and initiator
        require(msg.sender == flashLoanAddress, "Caller must be flash loan provider");
        require(initiator == address(this), "Initiator must be this contract");
        require(token == address(0), "Only ETH flash loans supported");

        emit FlashLoanReceived(msg.sender, initiator, amount, fee);

        // Decode arbitrage parameters
        (
            address tokenToTrade,
            address dex1,
            address dex2,
            uint256 tradeAmount,
            uint256 minProfit,
            uint256 minTokensBought,
            uint256 minEthReceived
        ) = abi.decode(data, (address, address, address, uint256, uint256, uint256, uint256));

        // Input validation
        require(tokenToTrade != address(0), "Invalid token address");
        require(dex1 != address(0) && dex2 != address(0), "Invalid DEX address");
        require(tradeAmount > 0 && tradeAmount <= amount, "Invalid trade amount");
        require(minTokensBought > 0, "Invalid min tokens bought");
        require(minEthReceived > 0, "Invalid min ETH received");

        // Step 1: Buy tokens on dex1 (cheaper DEX)
        IERC20(tokenToTrade).approve(dex1, tradeAmount);
        address[] memory path1 = new address[](2);
        path1[0] = address(0); // ETH
        path1[1] = tokenToTrade;
        (bool success1, bytes memory result1) = dex1.call{value: tradeAmount}(
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)",
                minTokensBought,
                path1,
                address(this),
                block.timestamp + deadLine
            )
        );
        if (!success1) {
            emit SwapFailed(dex1, tokenToTrade, "dex1 swap execution failed");
            revert("dex1 swap failed");
        }
        uint256[] memory amounts1 = abi.decode(result1, (uint256[]));
        uint256 tokensBought = amounts1[amounts1.length - 1]; // Last amount is output
        if (tokensBought < minTokensBought) {
            emit SwapFailed(dex1, tokenToTrade, "Slippage: too few tokens bought");
            revert("Slippage: too few tokens bought");
        }
        emit ArbitrageStep(dex1, tokenToTrade, tradeAmount, tokensBought);

        // Step 2: Sell tokens on dex2 (more expensive DEX)
        IERC20(tokenToTrade).approve(dex2, tokensBought);
        address[] memory path2 = new address[](2);
        path2[0] = tokenToTrade;
        path2[1] = address(0); // ETH
        (bool success2, bytes memory result2) = dex2.call(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
                tokensBought,
                minEthReceived,
                path2,
                address(this),
                block.timestamp + deadLine
            )
        );
        if (!success2) {
            emit SwapFailed(dex2, tokenToTrade, "dex2 swap execution failed");
            revert("dex2 swap failed");
        }
        uint256[] memory amounts2 = abi.decode(result2, (uint256[]));
        uint256 ethReceived = amounts2[amounts2.length - 1]; // Last amount is output
        if (ethReceived < minEthReceived) {
            emit SwapFailed(dex2, tokenToTrade, "Slippage: too little ETH received");
            revert("Slippage: too little ETH received");
        }
        IERC20(tokenToTrade).approve(dex2, 0); // Reset allowance
        emit ArbitrageStep(dex2, tokenToTrade, tokensBought, ethReceived);

        // Verify profitability
        uint256 totalRepayment = amount + fee;
        if (ethReceived < totalRepayment + minProfit) {
            emit SwapFailed(address(0), tokenToTrade, "Arbitrage not profitable");
            revert("Arbitrage not profitable");
        }

        // Repay flash loan
        if (address(this).balance < totalRepayment) {
            emit SwapFailed(address(0), tokenToTrade, "Insufficient ETH for repayment");
            revert("Insufficient ETH for repayment");
        }
        payable(flashLoanAddress).transfer(totalRepayment);
        emit LoanRepaid(flashLoanAddress, totalRepayment);

        // Transfer remaining profit
        uint256 profit = address(this).balance;
        if (profit > 0) {
            payable(profitAddress).transfer(profit);
            emit ProfitSent(profitAddress, profit);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Allow contract to receive ETH
    receive() external payable { }
}