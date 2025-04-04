// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Added import
import "./IDex.sol";

interface IFlashLoanProvider {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external;
}

contract Arbitrage is ReentrancyGuard { // Inherit ReentrancyGuard
    address public owner;
    address public profitAddress;
    IFlashLoanProvider public immutable flashLoanProvider;

    uint256 public constant DECIMALS = 10**18;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ProfitAddressChanged(address indexed oldProfitAddress, address indexed newProfitAddress);
    event ApproveToken(address indexed token, address indexed dex, uint256 amount);
    event WithdrawTokens(address indexed token, uint256 amount);
    event WithdrawETH(address indexed to, uint256 amount);

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

    function _approveToken(address token, address dex, uint256 amount) internal {
        require(IERC20(token).approve(dex, amount), "Token approval failed");
        emit ApproveToken(token, dex, amount);
    }

    function run(
        address token,
        address dexCheap,
        address dexExpensive,
        uint256 amount,
        uint256 deadlineBlock
    ) external onlyOwner nonReentrant { // Added nonReentrant
        require(block.number <= deadlineBlock, "Transaction deadline exceeded");

        uint256 priceCheap = IDex(dexCheap).getTokenPrice(token);
        uint256 priceExpensive = IDex(dexExpensive).getTokenPrice(token);
        require(priceCheap < priceExpensive, "No arbitrage opportunity");

        uint256 ethToSpend = (amount * priceCheap) / DECIMALS;

        bytes memory data = abi.encode(token, dexCheap, dexExpensive, amount);
        flashLoanProvider.flashLoan(address(this), address(0), ethToSpend, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external nonReentrant returns (bytes32) { // Added nonReentrant
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

        return keccak256("FlashLoanBorrower.onFlashLoan");
    }

    function withdrawTokens(address token, uint256 amount)
    external
    onlyOwner
    nonReentrant // Added nonReentrant
    {
        require(IERC20(token).transfer(owner, amount), "Withdrawal failed");
        emit WithdrawTokens(token, amount);
    }

    function withdrawETH(uint256 amount)
    external
    onlyOwner
    nonReentrant // Added nonReentrant
    {
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH withdrawal failed");
        emit WithdrawETH(owner, amount);
    }

    receive() external payable {}
}