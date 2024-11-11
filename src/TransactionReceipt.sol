// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Define the struct for each log entry
struct LogEntry {
    address addr;
    bytes32[] topics;
    bytes data;
    bytes32 blockHash;
    uint256 blockNumber;
    bytes32 transactionHash;
    uint256 transactionIndex;
    uint256 logIndex;
    bool removed;
}

// Define the main struct for the transaction receipt
struct TransactionReceipt {
    string status;
    uint256 cumulativeGasUsed;
    LogEntry[] logs;
    bytes logsBloom;
    uint8 txType;
    string transactionHash;
    uint256 transactionIndex;
    bytes32 blockHash;
    uint256 blockNumber;
    uint256 gasUsed;
    uint256 effectiveGasPrice;
    address from;
    address to;
    address contractAddress; // Nullable field represented as an address
}
