#!/bin/sh
set -x  # Enable debugging output
set -e  # Exit on any error
clear

# Load environment variables
. ./.env

# Clean up any previous Forge build artifacts
forge clean

contract="Pigfox"
forge flatten src/"$contract".sol --output flattened/"$contract"Flattened.sol

# Analyze the contract with Slither
docker pull trailofbits/eth-security-toolbox

# Ensure the correct path is passed to Slither
docker run --rm -v "$(pwd):/project" trailofbits/eth-security-toolbox \
    slither /project/flattened/"$contract"Flattened.sol
