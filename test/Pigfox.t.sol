// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Dex} from "../src/Dex.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {Pigfox} from "../src/Pigfox.sol";
import {Vault} from "../src/Vault.sol";


contract PigfoxTest is Test {
    Vault public vault;
    Dex public dex1;
    Dex public dex2;
    ERC20Token public erc20Token;
    Pigfox public pigfox;
    uint256 maxTokenSupply = 10 ether;

    function setUp() public {
        
        //Localhost
        vault = new Vault();
        dex1 = new Dex();
        dex1.setName("1");
        dex1.getName();
        
         /*
        vault = Vault(vm.envAddress("Vault"));
        dex1 = Dex("0xAe0Ba418186991b2bE5C274CDB316B16dD4e5B91);
        console.log("dex1:", address(dex1));
        
        dex1.getName();
        dex1.setName("1");
        */
        /*
        try {
            dex1.setName("1");
        } catch Error(string memory reason) {
            console.log("Error reason:", reason);
        }
        */
         /*
        dex2 = Dex(vm.envAddress("Dex2"));
        dex2.setName("2");
        erc20Token = ERC20Token(vm.envAddress("ERC20Token"));
        erc20Token.mint(maxTokenSupply);
        console.log("erc20Token.getSuppy():", erc20Token.getSuppy());
        erc20Token.transfer(address(vault), maxTokenSupply);
        erc20Token.supplyToken(address(dex1), 5000000000);
        erc20Token.supplyToken(address(dex2), 3000000000);
        console.log("erc20Token.balanceOf(address(dex1)):", erc20Token.balanceOf(address(dex1)));
        console.log("erc20Token.balanceOf(address(dex2)):", erc20Token.balanceOf(address(dex2)));
        */
    }

    function test_pigfox() public {
        /*
        address equalizerLenderAddress = vm.envAddress("SEPOLIA_EQUALIZER_LENDER");
        pigfox = new Pigfox();
        pigfox.setLender(equalizerLenderAddress);
        vault.transerToken(address(erc20Token), address(pigfox), maxTokenSupply);
        dex1.setTokenPrice(address(erc20Token), 100);
        dex2.setTokenPrice(address(erc20Token), 80);
        if (dex1.getTokenPrice(address(erc20Token)) == dex2.getTokenPrice(address(erc20Token))) {
            revert("Prices are equal");
        }

        bytes memory data = abi.encode(address(dex1), address(dex2), address(erc20Token));
        bytes32 dataBytes = pigfox.onFlashLoan(address(pigfox), address(erc20Token), maxTokenSupply, 0, data);
        console.log("data", bytes32ToString(dataBytes));
        */
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
