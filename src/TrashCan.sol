// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TrashCan {
    // Event for ETH deposits
    event EthReceived(address indexed sender, uint256 amount);

    // Event for ERC20 token deposits
    event TokenReceived(address indexed token, address indexed sender, uint256 amount);

    // Fallback function to accept ETH
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    // Function to receive ERC20 tokens
    function depositToken(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        emit TokenReceived(token, msg.sender, amount);
    }
}
