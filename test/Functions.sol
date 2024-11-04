// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Router} from "../src/Router.sol";
import {XToken} from "../src/XToken.sol";

contract Functions is Test{
 function getXTokens(string calldata _xToken, string calldata _deployer) public returns (XToken) {
     string[] memory inputs = new string[](4);
     inputs[0] = "cast";
     inputs[1] = "call";
     inputs[2] = _deployer;
     inputs[3] = _xToken;
     bytes memory result = vm.ffi(inputs);

     // Decode the result to get the contract address
     address contractAddress = abi.decode(result, (address));

     return XToken(contractAddress);
 }
}
