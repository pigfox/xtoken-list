// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function tokenAmount(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function transerToken(address _tokenAddress, address _to, uint256 _amount) public {
        IERC20(_tokenAddress).approve(_to, _amount);
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
}