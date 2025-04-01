#!/bin/bash
clear
# Configuration
VERSION="0.8.26"
CONTRACT="Arbitrage"
SOLC_VERSION="0.8.26"

# Exit on any error
set -e

# Print commands as they are executed (for debugging)
set -x

# Create and activate virtual environment in the root directory
cd ..
python3 -m venv venv
source venv/bin/activate

# Install solc-select
pip install solc-select

# Install and configure solc version
solc-select install "$SOLC_VERSION"
solc-select use "$SOLC_VERSION"

# Verify solc version
solc --version

# Install Slither
pip3 install slither-analyzer

# Verify Slither version
slither --version

# Run Slither with absolute paths
slither "src/$CONTRACT.sol" --solc-remaps "@openzeppelin/contracts=/home/peter/Documents/crypto-projects/arbitrage-bot-v2-snippets/lib/openzeppelin-contracts/contracts"

# Clear previous installations
rm -rf venv

echo "Script completed successfully!"