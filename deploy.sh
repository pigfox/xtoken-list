#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
forge build

contract="Dex"
echo "Deploying $contract..."
forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify --optimize 200
#---Multi-Chain Deployment---
#forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$X_WALLET_PRIVATE_KEY" --broadcast --verify --optimize 200
#forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$AVAX_HTTP_RPC_URL" --private-key "$X_WALLET_PRIVATE_KEY" --broadcast --verify --optimize 200


#nonce=$(cast nonce "$WALLET_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
#forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$AVAX_HTTP_RPC_URL" --private-key "$PRIVATE_KEY" --nonce "$nonce" --broadcast --verify --optimize 200
#CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(string,string)" "PigfoxToken" "PFX")
#echo "Constructor Args: $CONSTRUCTOR_ARGS"
#CONTRACT_BYTECODE=$(cat out/PigfoxToken.sol/PigfoxToken.json | jq -r '.bytecode')
#echo "Contract Bytecode: $CONTRACT_BYTECODE"

#DEPLOY_BYTECODE="${CONTRACT_BYTECODE}${CONSTRUCTOR_ARGS}"
#nonce=$(cast nonce "$WALLET_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
#echo "Nonce: $nonce"
# Sepolia Deployment
#cast send --create "$DEPLOY_BYTECODE" \
#  --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
#  --from "$WALLET_ADDRESS" \
#  --private-key "$PRIVATE_KEY" \
#  --broadcast \
#  --verify \
#  --optimize 200



#nonce=$(cast nonce "$WALLET_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
#echo "Nonce: $nonce"
# Avalanche Testnet Deployment
#cast send \
#--create $DEPLOY_BYTECODE \
#--private-key $PRIVATE_KEY \
#--rpc-url "$AVAX_HTTP_RPC_URL" \
#--nonce "$nonce" \
#--broadcast \
#--verify \
#--optimize 200


#cast nonce <DEPLOYER_ADDRESS> --rpc-url <RPC_URL>