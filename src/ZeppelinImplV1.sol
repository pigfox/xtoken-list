// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ZeppelinImplV1 {
    uint256 public value;

    event ValueChanged(uint256 newValue);

    function setValue(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value);
    }
}
