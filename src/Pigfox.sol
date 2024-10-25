// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
//import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
//import "equalizer/contracts/interfaces/IEqualizerLender.sol";
import {console} from "../lib/forge-std/src/console.sol";

contract Pigfox {
    address public owner;
    address public destination;

    event Swapped(address indexed token, address indexed fromDex, address indexed toDex, uint256 amount);

    constructor() {
        owner = msg.sender;
        destination = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setDestination(address _destination) public onlyOwner {
        destination = _destination;
    }

    function getDestination() public view returns (address) {
        return destination;
    }

    function swap(address _tokenAddress, address _fromDexAddress, address _toDexAddress, uint256 _amount) public {
        // Check that the supply of _tokenAddress at _fromDexAddress is greater than _amount
        ERC20 token = ERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(_fromDexAddress);
        require(tokenBalance >= _amount, "Insufficient balance");

        // Transfer _amount of _tokenAddress from _fromDexAddress to _toDexAddress
        token.transferFrom(_fromDexAddress, _toDexAddress, _amount);

        // Emit transfer event
        emit Swapped(_tokenAddress, _fromDexAddress, _toDexAddress, _amount);
    }
}