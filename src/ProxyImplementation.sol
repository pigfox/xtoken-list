// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ProxyImplementation
/// @dev This contract can be used as the implementation logic for a proxy.
contract ProxyImplementation {
    // Storage variable to hold a single value
    uint256 public value;

    // Event emitted when the value changes
    event ValueChanged(uint256 indexed newValue);

    /// @notice Sets a new value
    /// @param _value The new value to be stored
    function setValue(uint256 _value) public {
        value = _value;
        emit ValueChanged(_value);
    }

    /// @notice Retrieves the stored value
    /// @return The current value
    function getValue() public view returns (uint256) {
        return value;
    }

    /// @notice Allows the contract to receive Ether
    receive() external payable { }

    /// @notice Fallback function for handling calls with data
    fallback() external payable { }
}
