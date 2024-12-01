#!/bin/sh
set -x  # Enable debugging output
set -e  # Exit on any error
clear

# Load environment variables
. ./.env

# Clean up any previous Forge build artifacts
forge clean
start_time=$(date +%s)
contract="Dex"

#forge flatten src/"$contract".sol --output flattened/"$contract"Flattened.sol
echo "Slithering $contract..."
ls -l flattened/"$contract"Flattened.sol

chmod 644 flattened/"$contract"Flattened.sol

solcVersion="0.8.26"
echo "Pull Solc $solcVersion..."
docker pull ethereum/solc:"$solcVersion"

echo "Myth $contract..."
docker pull mythril/myth
docker run -v $(pwd):/project mythril/myth analyze /project/flattened/"$contract"Flattened.sol

# Analyze the contract with Slither
docker pull trailofbits/eth-security-toolbox

# Ensure the correct path is passed to Slither
docker run --rm -v "$(pwd):/project" trailofbits/eth-security-toolbox slither /project/flattened/"$contract"Flattened.sol

end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "Execution time: ${execution_time} seconds"

#docker run --rm -it -v $(pwd):/project ghcr.io/crytic/echidna/echidna
#docker build -t echidna -f docker/Dockerfile --target final-ubuntu .
#docker run -it -v $(pwd):/project echidna bash -c "solc-select install $solcVersion && solc-select use $solcVersion && echidna /project/flattened/"$contract"Flattened.sol

