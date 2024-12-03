// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop {
    IERC20 public token;
    address public owner;

    event TokenTransferred(address recipient, uint256 amount);
    event AttemptedAirdrop(string message);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function airdropTokens(address _tokenAddress, address[] memory _addresses, uint256 _amount) public {//onlyOwner
        emit AttemptedAirdrop("Attempting to airdrop tokens 1");
        require(_addresses.length > 0, "No addresses provided");
        emit AttemptedAirdrop("Attempting to airdrop tokens 2");

        token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            address recipient = _addresses[i];
            bool success = token.transfer(recipient, _amount);
            if (success) {
                emit TokenTransferred(recipient, _amount);
            }
        }
    }
}