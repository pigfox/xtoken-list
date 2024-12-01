// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// src/Dex.sol

contract Dex {
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public tokenPrice;
    address public owner;

    event TokensDeposited(address indexed tokenAddress, uint256 amount);
    event TokenPriceSet(address indexed tokenAddress, uint256 price);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setTokenPrice(address _address, uint256 _newPrice) public onlyOwner{
        tokenPrice[_address] = _newPrice;
        emit TokenPriceSet(_address, _newPrice);
    }

    function getTokenPriceOf(address _address) external view returns (uint256) {
        return tokenPrice[_address];
    }

    function getTokenBalanceOf(address _address) external view returns (uint256) {
        return tokenBalance[_address];
    }

    function depositTokens(address _token, address _source, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        bool success = IERC20(_token).transferFrom(_source, address(this), _amount);
        require(success, "Token transfer failed");

        tokenBalance[_token] += _amount;
        emit TokensDeposited(_token, _amount);
    }

    function withdrawTokens(address _token, address _destination, uint256 _amount) external onlyOwner{
        require(_amount > 0 && tokenBalance[_token] >= _amount, "Insufficient balance");
        tokenBalance[_token] -= _amount;

        bool success = IERC20(_token).transfer(_destination, _amount);
        require(success, "Token transfer failed");
    }

    // Allow the contract to receive ETH
    receive() external payable {}
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
    }
}
