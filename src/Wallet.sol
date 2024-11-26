// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IArbitrageContract {
    function addAccessor(address _accessor) external;
    function run(uint256 amount) external;
}

contract Wallet {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Wallet: Not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function addAccessor(address _target, address _accessor) public onlyOwner {
        IArbitrageContract(_target).addAccessor(_accessor);
    }

    /*
    function callAnotherFunction(address target, address user) external view onlyOwner returns (uint256) {
        return IArbitrageContract(target).anotherFunction(user);
    }
    */
}
