// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("My Token", "MTK") {
        _mint(msg.sender, 1000 * 10**18);
    }

    function approveAndTransfer(address spender, uint256 amount, address recipient) public returns (bool) {
        // Approve the spender to transfer a specific amount of tokens on your behalf
        _approve(msg.sender, spender, amount);

        // Transfer the approved amount of tokens to the recipient
        return transferFrom(msg.sender, recipient, amount);
    }

    function checkAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }
}
*/
/*

Explanation:
* approveAndTransfer() Function:
   * Approving the Spender: The _approve() function is used to grant the spender permission to transfer amount tokens on behalf of the msg.sender.
   * Transferring Tokens: The transferFrom() function is then called to transfer the approved tokens from the msg.sender to the recipient.
* checkAllowance() Function:
   * This function demonstrates how to query the current allowance of a spender for a specific owner.
Using the Contract:
* Deploy the Contract: Deploy the MyToken contract to a blockchain.
* Grant Approval: Call the approveAndTransfer() function on the deployed contract, specifying the spender, amount, and recipient.
* Check Allowance: Call the checkAllowance() function to verify the remaining allowance of the spender.
Remember:
* Always be cautious when granting approvals, especially to third-party contracts.
* Consider using safer approaches like increaseAllowance() and decreaseAllowance() to avoid potential security risks.
* Thoroughly test your contracts to ensure correct functionality and security.
By understanding and effectively using these functions, you can build secure and robust decentralized applications on the Ethereum blockchain.
* https://devsolus.com/2022/07/24/created-custom-erc20-contract-balanceof-msg-sender-is-zero/
* https://github.com/vasik551/Token-Faucet
*/
