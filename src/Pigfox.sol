// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
//import "equalizer/contracts/interfaces/IEqualizerLender.sol";
import {console} from "../lib/forge-std/src/console.sol";

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

/*
*  FlashBorrowerExample is a simple smart contract that enables
*  to borrow and returns a flash loan.
*/
contract Pigfox is IERC3156FlashBorrower {
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == initiator, "Unauthorized lender");
        (address buyDexAddress, address sellDexAddress, address tokenAddress) = abi.decode(data, (address, address, address));
        console.log("Flash loan initiated by: ", initiator);
        console.log("Token: ", token);
        console.log("Amount: ", amount);
        console.log("Fee: ", fee);
        console.log("buyDexAddress: ", buyDexAddress);
        console.log("sellDexAddress: ", sellDexAddress);
        console.log("assetTokenAddress: ", tokenAddress);

        // Set the allowance to payback the flash loan
        IERC20(address(tokenAddress)).approve(msg.sender, MAX_INT);

        // Build your trading business logic here
        // e.g., sell on uniswapv2
        // e.g., buy on uniswapv3

        uint256 amountOwing = amount + fee;
        IERC20(tokenAddress).transfer(initiator, amountOwing); // Repay the loan

        return keccak256("IEqualizerFlashBorrower.onFlashLoan");
    }
}
