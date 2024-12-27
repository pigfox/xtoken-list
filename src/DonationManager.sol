// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DonationManager
 * @dev Manages ETH donations, ensuring security, transparency, and real-time tracking.
 */
contract DonationManager is ReentrancyGuard, Ownable {
    // Donation record structure
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    // Address receiving donations
    address public donationReceiver;

    // Array to store all donation records
    Donation[] private donations;

    // Total value of all donations
    uint256 private totalDonated;

    // Event emitted when a donation is successfully made
    event DonationReceived(address indexed donor, uint256 amount, uint256 timestamp);

    // Event emitted when the donation receiver address is updated
    event DonationReceiverUpdated(address indexed newReceiver);

    // Event emitted when funds are sent from the contract
    event FundsSent(address indexed recipient, uint256 amount);

    // Event emitted when the owner is updated
    event OwnerUpdated(address indexed newOwner);

    /**
     * @dev Initializes the contract with the address to receive donations.
     * @param _donationReceiver The address designated to receive all donations.
     */
    constructor(address _donationReceiver) {
        require(_donationReceiver != address(0), "Invalid receiver address");
        donationReceiver = _donationReceiver;
        _transferOwnership(msg.sender); // Set the deployer as the initial owner
    }

    /**
     * @dev Fallback function to reject non-ETH transactions.
     */
    fallback() external payable {
        revert("Only direct ETH donations are accepted");
    }

    /**
     * @dev Receive function to accept ETH donations and log them on-chain.
     */
    receive() external payable nonReentrant {
        require(msg.value > 0, "Donation must be greater than 0");

        // Record the donation
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        // Update total donated value
        totalDonated += msg.value;

        // Emit the donation event
        emit DonationReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Allows the owner to update the donation receiver address.
     * @param _newReceiver The new address to receive donations.
     */
    function updateDonationReceiver(address _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "Invalid receiver address");
        donationReceiver = _newReceiver;
        emit DonationReceiverUpdated(_newReceiver);
    }

    /**
     * @dev Allows the owner to send donations to a specific address.
     * @param recipient The address to send the donations to.
     * @param amount The amount of ETH to send.
     */
    function sendDonations(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send funds");

        emit FundsSent(recipient, amount);
    }

    /**
     * @dev Allows the owner to update the contract owner to a new address.
     * @param newOwner The address of the new owner.
     */
    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        _transferOwnership(newOwner);
        emit OwnerUpdated(newOwner);
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The total count of donations.
     */
    function getTotalDonations() external view returns (uint256) {
        return donations.length;
    }

    /**
     * @dev Retrieves donation details by index.
     * @param index The index of the donation to retrieve.
     * @return donor The address of the donor.
     * @return amount The amount of ETH donated.
     * @return timestamp The timestamp of the donation.
     */
    function getDonation(uint256 index)
    external
    view
    returns (
        address donor,
        uint256 amount,
        uint256 timestamp
    )
    {
        require(index < donations.length, "Index out of bounds");
        Donation memory donation = donations[index];
        return (donation.donor, donation.amount, donation.timestamp);
    }

    /**
     * @dev Returns the total value of all donations.
     * @return The total amount of ETH donated.
     */
    function getTotalDonatedValue() external view returns (uint256) {
        return totalDonated;
    }
}
