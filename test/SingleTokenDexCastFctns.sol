// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ConversionsTest} from "./Conversions.sol";
import {Dex} from "../src/Dex.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
//import {TransactionReceipt} from "../src/TransactionReceipt.sol";
import {XToken} from "../src/XToken.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract SingleTokenDexCastFctnsTest is Test{
    using stdJson for string;
}