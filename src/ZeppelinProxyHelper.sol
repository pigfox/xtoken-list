// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITransparentUpgradeableProxy {
    function admin() external view returns (address);
    function implementation() external view returns (address);
}

contract ZeppelinProxyHelper {
    function getAdmin(address proxy) external view returns (address) {
        return ITransparentUpgradeableProxy(proxy).admin();
    }

    function getImplementation(address proxy) external view returns (address) {
        return ITransparentUpgradeableProxy(proxy).implementation();
    }
}
