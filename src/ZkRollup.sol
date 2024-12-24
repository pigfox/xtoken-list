// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ZkRollup {
    address public owner;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // Deposit funds into the zk-rollup
    function deposit() external payable {
        require(msg.value > 0, "Must deposit non-zero value");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw funds with proof verification
    function withdraw(uint256 amount, bytes32 proof) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Verify proof (simulated by checking the hash of (address, amount))
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.sender, amount));
        require(proof == expectedHash, "Invalid proof");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}
