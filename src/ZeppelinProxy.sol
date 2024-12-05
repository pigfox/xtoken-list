// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ZeppelinProxy {
    TransparentUpgradeableProxy public proxy;

    constructor(address _logic, address _admin, bytes memory _data) {
        proxy = new TransparentUpgradeableProxy(_logic, _admin, _data);
    }

    function proxyAddress() external view returns (address) {
        return address(proxy);
    }
}
