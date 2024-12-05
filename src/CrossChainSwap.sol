// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@layerzero/contracts/lzApp/interfaces/ILayerZeroEndpoint.sol";
import "@layerzero/contracts/lzApp/interfaces/ILayerZeroReceiver.sol";

contract CrossChainSwap is ILayerZeroReceiver {
    ILayerZeroEndpoint public immutable endpoint;
    address public tokenAddress;

    constructor(address _endpoint, address _tokenAddress) {
        endpoint = ILayerZeroEndpoint(_endpoint); // LayerZero Endpoint
        tokenAddress = _tokenAddress;            // Token to bridge
    }

    // Function to swap tokens to another chain
    function swap(
        uint16 _dstChainId,
        bytes calldata _dstAddress,
        uint256 _amount
    ) external payable {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer tokens from user to the contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // Encode the payload to send to the destination chain
        bytes memory payload = abi.encode(msg.sender, _amount);

        // Send LayerZero message
        endpoint.send{value: msg.value}(
            _dstChainId,     // Destination chain ID
            _dstAddress,     // Destination contract address
            payload,         // Encoded payload
            payable(msg.sender), // Refund address
            address(0),      // ZRO payment address
            bytes("")        // Adapter parameters
        );
    }

    // Function to receive the tokens on the destination chain
    function lzReceive(
        uint16, // _srcChainId
        bytes memory, // _srcAddress
        uint64, // _nonce
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint), "Invalid caller");

        // Decode the payload
        (address recipient, uint256 amount) = abi.decode(_payload, (address, uint256));

        // Transfer the tokens to the recipient
        IERC20(tokenAddress).transfer(recipient, amount);
    }

    // Allow the contract to receive Ether for LayerZero fees
    receive() external payable {}
}
