// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Proxy {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation address is not set");

        // Delegate call to the implementation contract
        (bool success, bytes memory data) = impl.delegatecall(msg.data);

        // Check the result and either revert or return
        if (!success) {
            // Revert with the returned data
            revert(string(data));
        }
        // Return the returned data
        assembly {
            return(add(data, 32), mload(data))
        }
    }


    /*
    /// @notice Handles calls with data
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation address is not set");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
*/
    /// @notice Handles plain Ether transfers with no data
    receive() external payable {
        // Optionally add custom logic here (e.g., emit an event)
    }

    /// @notice Updates the address of the implementation contract
    /// @param _newImplementation The address of the new implementation
    function updateImplementation(address _newImplementation) public {
        implementation = _newImplementation;
    }
}
