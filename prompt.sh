#!/bin/sh
set -x
set -e
clear

#tree -L 2
cat src/AAVE.sol
cat src/Arbitrage.sol
cat src/Dex.sol
cat src/PigfoxToken.sol

set +x
heredoc=$(cat <<'EOF'
CONTEXT:
The purpose is to build a Solidity Ethreum arbitrage contract that takes a AAVE flashloan and executes an arbitrage between two DEXs see Dex.sol.
Your task is:
#1 Review the Dex.sol, make sure it can act as a ficticious DEX holding PigfoxToekn.sol of varying value prt Dex.
#2 Create a contract AAVE.sol and make it so that it can simulate the the real AAVE flashloan contract and can provide flashloans.
#2 Review the Arbitrage.sol contract, make sure it can take a flashloan from the ficticious AAVE.sol using `function onFlashLoan` 

Then we are going to make an arbitrage between two arbitrary DEXs, first on Sepolia Testnet and then on Ethereum Mainnet.
It needs to work flawlessly on both networks.

Instructions:
See above.




If you don't understand, ask me questions.
EOF
)

echo "$heredoc"
#https://grok.com/chat/3b9152f9-b48b-4dcb-82b5-54199e75036a