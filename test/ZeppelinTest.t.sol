// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console, Vm} from "forge-std/Test.sol";
import {
ITransparentUpgradeableProxy,
TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ZeppelinImplV1} from "../src/ZeppelinImplV1.sol";
import {ZeppelinImplV2} from "../src/ZeppelinImplV2.sol";

contract ZeppelinTest is Test {
    address admin = vm.envAddress("WALLET_ADDRESS");
    TransparentUpgradeableProxy proxy;
    ZeppelinImplV1 implementationV1;
    ZeppelinImplV2 implementationV2;
    address proxyAdmin;
    address implementationV2Owner = makeAddr("implementationV2Owner");

    function setUp() public {
        implementationV1 = new ZeppelinImplV1();
        vm.recordLogs();
        proxy = new TransparentUpgradeableProxy(
            address(implementationV1), admin, ""
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (, proxyAdmin) = abi.decode(entries[entries.length - 1].data, (address, address));
    }

    function testAll() public {
        testAdminWallet();
        testProxyFunctionality();
        testUpgrade();
    }

    function testAdminWallet() public view{
        assertEq(admin, admin);
    }

    function testProxyFunctionality() public {
        ZeppelinImplV1 proxiedContract = ZeppelinImplV1(address(proxy));
        proxiedContract.setValue(42);
        assertEq(proxiedContract.value(), 42);

        proxiedContract.setValue(100);
        assertEq(proxiedContract.value(), 100);
    }

    function testUpgrade() public {
        implementationV2 = new ZeppelinImplV2();

        vm.prank(admin); // Simulate admin upgrading the proxy
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(implementationV2),
            abi.encodeWithSignature("initialize(address)", implementationV2Owner)
        );

        ZeppelinImplV2 proxiedContract = ZeppelinImplV2(address(proxy));
        vm.prank(implementationV2Owner);
        proxiedContract.setValue(200);
        assertEq(proxiedContract.value(), 200);
    }
}