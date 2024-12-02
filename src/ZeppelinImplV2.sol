// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ZeppelinImplV2 {
    uint256 public value;
    address public owner;

    event ValueChanged(uint256 newValue);

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value);
    }
}
