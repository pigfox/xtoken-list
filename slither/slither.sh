#!/bin/bash

# Configuration
VERSION="0.8.26"
CONTRACT="Arbitrage"

# Exit on any error
set -e

# Print commands as they are executed (for debugging)
set -x

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install and configure solc-select
solc-select install
solc-select install "$VERSION"
solc-select use "$VERSION"

# Verify solc version
solc --version

# Install Slither
pip3 install slither-analyzer

# Verify Slither version
slither --version

# Run Slither on the contract with OpenZeppelin remapping
slither "../src/$CONTRACT.sol" --solc-remaps "@openzeppelin/contracts/=../lib/openzeppelin-contracts/contracts/"

# Optionally deactivate the virtual environment (uncomment if desired)
deactivate
# Clear previous installations
rm -rf venv

echo "Script completed successfully!"