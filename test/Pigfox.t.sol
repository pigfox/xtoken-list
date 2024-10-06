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
        vault = new Vault();
        dex1 = new Dex("1");
        dex2 = new Dex("2");
        erc20Token = new ERC20Token(maxTokenSupply);
        console.log("erc20Token.getSuppy():", erc20Token.getSuppy());
        erc20Token.approve(address(vault), maxTokenSupply);
        erc20Token.transfer(address(vault), maxTokenSupply);
    }

    function test_pigfox() public {
        address equalizerLenderAddress = vm.envAddress("SEPOLIA_EQUALIZER_LENDER");
        pigfox = new Pigfox(equalizerLenderAddress);
        vault.transerToken(address(erc20Token), address(pigfox), maxTokenSupply);
        dex1.setTokenPrice(address(erc20Token), 80);
        dex2.setTokenPrice(address(erc20Token), 100);


        bytes memory data = abi.encode(address(dex1), address(dex2), address(erc20Token));
        bytes32 dataBytes = pigfox.onFlashLoan(address(pigfox), address(erc20Token), maxTokenSupply, 0, data);
        console.log("data", bytes32ToString(dataBytes));
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
