#!/bin/sh
set -x
set -e
clear
. ./.env

echo "Running arbitrage simulation"

# Set token price for Router1
cast send "$Router1" "setTokenPrice(address,uint256)" "$XToken" "120" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Set token price for Router2
cast send "$Router2" "setTokenPrice(address,uint256)" "$XToken" "80" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Mint and supply tokens to the test contract
cast send "$XToken" "supplyTokenTo(address,uint256)" "$Router1" "5000000000000000000" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Check test contract's balance
cast call "$XToken" "balanceOf(address)" "$TEST_CONTRACT" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

# Supply tokens to Router1
cast send "$XToken" "supplyTokenTo(address,uint256)" "$Router1" "2500000000000000000" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Check Router1’s balance
cast call "$XToken" "balanceOf(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

# Approve Router1 for maximum tokens
cast send "$XToken" "approve(address,uint256)" "$Router1" "$(cast --max-uint)" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Approve Router2 for maximum tokens
cast send "$XToken" "approve(address,uint256)" "$Router2" "$(cast --max-uint)" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Get token prices from Router1 and Router2
ROUTER1_PRICE=$(cast call "$Router1" "getTokenPrice(address)" "$XToken" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
ROUTER2_PRICE=$(cast call "$Router2" "getTokenPrice(address)" "$XToken" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

# Decide and execute arbitrage
if [ "$ROUTER1_PRICE" -lt "$ROUTER2_PRICE" ]; then
    echo "Executing arbitrage: Buy from Router1, sell to Router2."
    ROUTER1_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    cast send "$Arbitrage" "executeArbitrage(address,address,address,address,uint256)" "$XToken" "$Router1" "$Router2" "$Vault" "$ROUTER1_BALANCE" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
elif [ "$ROUTER2_PRICE" -lt "$ROUTER1_PRICE" ]; then
    echo "Executing arbitrage: Buy from Router2, sell to Router1."
    ROUTER2_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router2" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    cast send "$Arbitrage" "executeArbitrage(address,address,address,address,uint256)" "$XToken" "$Router2" "$Router1" "$Vault" "$ROUTER2_BALANCE" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
else
    echo "No arbitrage opportunity found."
fi



