#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean

#1. Stake Tokens
# Approve the Stake contract to spend tokens
cast send "$PIGFOX_TOKEN" "approve(address,uint256)" \
    "$STAKE" 1000000000000000000 \
    --private-key "$PRIVATE_KEY" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

# Stake tokens into the contract
cast send "$STAKE" "stake(uint256)" \
    1000000000000000000 \
    --private-key "$PRIVATE_KEY" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

#2
# Withdraw tokens from the contract
cast send "$STAKE" "withdraw(uint256)" \
    500000000000000000 \
    --private-key "$PRIVATE_KEY" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

#3
# Claim rewards earned for staking
cast send "$STAKE" "claimReward()" \
    --private-key "$PRIVATE_KEY" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

#4
# Check the staked amount for the WALLET_ADDRESS
cast call "$STAKE" \
    "stakers(address)(uint256,uint256)" \
    "$WALLET_ADDRESS" \
    --rpc-url "$SEPOLIA_HTTP_RPC_URL"

# Check the total staked tokens in the contract
cast call "$STAKE" \
    "totalStaked()(uint256)" \
    --rpc-url <"$SEPOLIA_HTTP_RPC_URL"
