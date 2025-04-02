// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDex.sol"; // Use generic interface

interface IFlashLoanProvider {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external;
}

contract Arbitrage {
    address public owner;
    address public profitAddress;
    IFlashLoanProvider public immutable flashLoanProvider;
    mapping(address => bool) public accessors;

    // Constants
    uint256 public constant DECIMALS = 10**18; // Standard ERC20 decimal places

    // Events
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ProfitAddressChanged(address indexed oldProfitAddress, address indexed newProfitAddress);

    constructor(address _flashLoanProvider) {
        owner = msg.sender;
        profitAddress = msg.sender;
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
        accessors[msg.sender] = true; // Owner has access by default
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAccessor() {
        require(accessors[msg.sender], "Not an authorized accessor");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Invalid owner address");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setProfitAddress(address _profitAddress) external onlyOwner {
        require(_profitAddress != address(0), "Invalid profit address");
        emit ProfitAddressChanged(profitAddress, _profitAddress);
        profitAddress = _profitAddress;
    }

    function addAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = true;
    }

    function removeAccessor(address _accessor) external onlyOwner {
        accessors[_accessor] = false;
    }

    // Approve tokens for spending by a DEX
    function _approveToken(address token, address dex, uint256 amount) internal {
        require(IERC20(token).approve(dex, amount), "Token approval failed");
    }

    // Execute arbitrage with flash loan: Buy from cheaper DEX, sell to expensive DEX
    function run(
        address token,
        address dexCheap, // DEX with lower price (buy here)
        address dexExpensive, // DEX with higher price (sell here)
        uint256 amount, // Amount of tokens to trade
        uint256 deadlineBlock // Block number deadline
    ) external onlyAccessor {
        require(block.number <= deadlineBlock, "Transaction deadline exceeded");

        // Get prices from both DEXes
        uint256 priceCheap = IDex(dexCheap).getTokenPrice(token);
        uint256 priceExpensive = IDex(dexExpensive).getTokenPrice(token);
        require(priceCheap < priceExpensive, "No arbitrage opportunity");

        // Calculate ETH needed to buy tokens from cheap DEX
        uint256 ethToSpend = (amount * priceCheap) / DECIMALS;

        // Request flash loan for ETH
        bytes memory data = abi.encode(token, dexCheap, dexExpensive, amount);
        flashLoanProvider.flashLoan(address(this), address(0), ethToSpend, data);
    }

    // Flash loan callback
    function onFlashLoan(
        address initiator,
        address token, // ETH is address(0)
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender == address(flashLoanProvider), "Untrusted caller");
        require(initiator == address(this), "Invalid initiator");
        require(token == address(0), "Only ETH flash loans supported");

        (address tokenToTrade, address dexCheap, address dexExpensive, uint256 amountToTrade) =
                            abi.decode(data, (address, address, address, uint256));

        // Buy tokens from cheaper DEX with borrowed ETH
        uint256 tokensBought = IDex(dexCheap).buyTokens{value: amount}(tokenToTrade, amountToTrade);
        require(tokensBought >= amountToTrade, "Failed to buy enough tokens");

        // Approve expensive DEX to spend tokens
        _approveToken(tokenToTrade, dexExpensive, tokensBought);

        // Sell tokens to expensive DEX
        uint256 ethReceived = IDex(dexExpensive).sellTokens(tokenToTrade, tokensBought);

        // Calculate profit
        uint256 totalRepayment = amount + fee;
        require(ethReceived >= totalRepayment, "Arbitrage not profitable");
        uint256 profit = ethReceived - totalRepayment;

        // Repay flash loan
        (bool sentRepayment, ) = address(flashLoanProvider).call{value: totalRepayment}("");
        require(sentRepayment, "Loan repayment failed");

        // Transfer profit to profitAddress
        if (profit > 0) {
            (bool sentProfit, ) = profitAddress.call{value: profit}("");
            require(sentProfit, "Profit transfer failed");
        }

        // Return success identifier (matches Vault's expectation)
        return keccak256("FlashLoanBorrower.onFlashLoan");
    }

    // Withdraw tokens or ETH (for owner cleanup)
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
    }

    // Allow contract to receive ETH
    receive() external payable {}
}
