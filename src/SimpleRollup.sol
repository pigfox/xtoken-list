// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleRollup {
    event BatchSubmitted(uint256 batchId, bytes32 stateRoot);

    struct Batch {
        bytes32 stateRoot;
        uint256 timestamp;
    }

    mapping(uint256 => Batch) public batches;
    uint256 public batchCounter;

    function submitBatch(bytes32 _stateRoot) external {
        batchCounter++;
        batches[batchCounter] = Batch(_stateRoot, block.timestamp);
        emit BatchSubmitted(batchCounter, _stateRoot);
    }
}
