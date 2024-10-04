

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {List} from "../src/List.sol";
import {Dex} from "../src/Dex.sol";
import {XToken} from "../src/XToken.sol";

contract ListTest is Test {
    List public list;
    Dex public dex1;
    Dex public dex2;
    XToken public xtoken;
    uint maxTokenSupply = 10 ether;

    function setUp() public {
        dex1 = new Dex("1");
        dex2 = new Dex("2");
        xtoken = new XToken(maxTokenSupply);
        list = new List(address(dex1), address(dex2), address(xtoken));
    }

    function test_list() public {
        list.run(maxTokenSupply);
    }
}
