// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ZeppelinImplV2 {
    uint256 public value;
    address public owner;

    event ValueChanged(uint256 newValue);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    function setValue(uint256 _value) external onlyOwner {
        value = _value;
        emit ValueChanged(_value);
    }
}
