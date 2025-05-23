#!/bin/sh
set -x
set -e
clear

#tree -L 2
cat src/Arbitrage.sol
cat test/CastFunctions.sol

set +x
heredoc=$(cat <<'EOF'
The purpose is to build a Solidity Ethreum arbitrage contract that takes a AAVE flashloan and executes an arbitrage between two DEXs.
You task is to implement the onFlahloan function ONLY, leave other functions alone. 
The onFlahloan function can only be called by owner.

Then we are going to make an arbitrage between two arbitrary DEXs, first on Sepolia Testnet and then on Ethereum Mainnet.
It needs to work flawlessly on both networks.

Instructions:
Take note of the following: you define a string array like this: string[] memory inputs = new string[](N);

Find me AAVE_LENDING_POOL_ADDRESS on both Ethereum Main net and Sepolia Test n



If you don't understand, ask me questions.
EOF
)

echo "$heredoc"
#https://grok.com/chat/3b9152f9-b48b-4dcb-82b5-54199e75036a