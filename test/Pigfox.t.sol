// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Dex} from "../src/Dex.sol";
import {XToken} from "../src/XToken.sol";
import {Pigfox} from "../src/Pigfox.sol";
import {Vault} from "../src/Vault.sol";

contract PigfoxTest is Test {
    Dex public dex1;
    Dex public dex2;
    XToken public xToken;
    Pigfox public pigfox;
    Vault public vault;
    uint256 public maxTokenSupply = 10 ether;

    function setUp() public {
        dex1 = Dex(vm.envAddress("Dex1"));
        dex2 = Dex(vm.envAddress("Dex2"));
        vault = Vault(payable(vm.envAddress("Vault")));
        pigfox = Pigfox(vm.envAddress("Pigfox"));
        xToken = XToken(vm.envAddress("XToken"));
        xToken.mint(maxTokenSupply);
        xToken.supplyTokenTo(address(dex1), 5000000000);
        xToken.supplyTokenTo(address(dex2), 3000000000);
        xToken.supplyTokenTo(address(vault), 1 ether);

        // Approve pigfox to spend tokens on behalf of both Dexes
        vm.prank(address(dex1));
        xToken.approve(address(pigfox), type(uint256).max);

        vm.prank(address(dex2));
        xToken.approve(address(pigfox), type(uint256).max);

        // Approve pigfox from the test contract
        xToken.approve(address(pigfox), type(uint256).max);

        dex1.setTokenPrice(address(xToken), 120);
        dex2.setTokenPrice(address(xToken), 80);
    }

    function test_swap()public {
        console.log("Test Swap");
        uint256 dex1TokenPrice = dex1.getTokenPrice(address(xToken));
        console.log("dex1TokenPrice:", dex1TokenPrice);
        uint256 dex2TokenPrice = dex2.getTokenPrice(address(xToken));
        console.log("dex2TokenPrice:", dex2TokenPrice);
        if (dex1TokenPrice == dex2TokenPrice) {
           revert("Prices are equal");
        }

        if (dex1TokenPrice < dex2TokenPrice){
            console.log("Buy from Dex1 sell to Dex2");
            uint256 dex1TokenBalance = xToken.balanceOf(address(dex1));
            pigfox.swap(address(xToken), address(dex1), address(dex2), dex1TokenBalance);
        }
        if (dex2TokenPrice < dex1TokenPrice){
            console.log("Buy from Dex2 sell to Dex1");
            uint256 dex2TokenBalance = xToken.balanceOf(address(dex2));
            pigfox.swap(address(xToken), address(dex2), address(dex1), dex2TokenBalance);
        }

    }

    function bytes32ToString(bytes32 _data) internal pure returns (string memory) {
        bytes memory tempBytes = new bytes(32);
        uint8 length = 0;

        for (uint8 i = 0; i < 32; i++) {
            bytes1 char = _data[i]; // Use bytes1 instead of byte
            if (char != 0) {
                tempBytes[length] = char;
                length++;
            } else {
                break;
            }
        }

        bytes memory result = new bytes(length);
        for (uint8 j = 0; j < length; j++) {
            result[j] = tempBytes[j];
        }

        return string(result);
    }
}
