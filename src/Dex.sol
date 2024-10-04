// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    mapping(address => uint256) public tokenPrices;
    string public name;

    //Set name of dex
    constructor(string memory _name) {
        name = _name;
    }

    //Get name of dex
    function getName() external view returns (string memory) {
        return name;
    }

    //Set price of individual token
    function setTokenPrice(address _tokenAddress, uint _xTokenprice) external {
        tokenPrices[_tokenAddress] = _xTokenprice;
    }

    //Get price of individual token
    function getTokenPrice(address _tokenAddress) external view returns (uint256) {
        return tokenPrices[_tokenAddress];
    }

    //Get value of all tokens
    function valueOfTokens(address _tokenAddress) external view returns (uint256) {
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(address(this)) * tokenPrices[_tokenAddress];
    }
}