// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AIPrediction {
    struct Prediction {
        uint256 timestamp;
        uint256 predictedPrice;
    }

    address public owner;
    Prediction[] public predictions;

    event PredictionAdded(uint256 timestamp, uint256 predictedPrice);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function addPrediction(uint256 predictedPrice) public onlyOwner {
        predictions.push(Prediction(block.timestamp, predictedPrice));
        emit PredictionAdded(block.timestamp, predictedPrice);
    }

    function getPrediction(uint256 index) public view returns (Prediction memory) {
        require(index < predictions.length, "Invalid prediction index");
        return predictions[index];
    }

    function getAllPredictions() public view returns (Prediction[] memory) {
        return predictions;
    }
}
