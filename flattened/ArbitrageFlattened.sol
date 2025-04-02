// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20 ^0.8.26;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// src/IDex.sol

interface IDex {
    function depositTokens(address token, uint256 amount) external;
    function buyTokens(address token, uint256 amount) external payable returns (uint256);
    function sellTokens(address token, uint256 amount) external returns (uint256);
    function setTokenPrice(address token, uint256 price) external;
    function getTokenPrice(address token) external view returns (uint256);
    function withdraw(address token, uint256 amount) external; // Added
}

// src/Arbitrage.sol

 // Use generic interface

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
