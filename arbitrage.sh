#!/bin/sh
set -x
set -e
clear
. ./.env

echo "Running arbitrage simulation"
hex2Int() {
    local hex_value="$1"

    # Clean the output by stripping '0x' and any extra whitespace
    hex_value=$(echo "$hex_value" | sed 's/^0x//' | tr -d '\n' | tr -d ' ')

    # Check if the value is not empty and valid for conversion
    if [ -z "$hex_value" ] || ! echo "$hex_value" | grep -qE '^[0-9a-fA-F]+$'; then
        echo "Error: Invalid hexadecimal value"
        return 1
    fi

    # Use printf to convert the large hex value to decimal
    numerical_value=$(printf "%d\n" "0x$hex_value" 2>/dev/null)

    if [ -z "$numerical_value" ]; then
        echo "Error: Failed to convert hexadecimal to decimal"
        return 1
    fi
    echo "$numerical_value"  # Return the decimal value
}

# Set token price for Router1
cast send "$Router1" "setTokenPrice(address,uint256)" "$XToken" "120" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Set token price for Router2
cast send "$Router2" "setTokenPrice(address,uint256)" "$XToken" "80" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Mint and supply tokens to the test contract
cast send "$XToken" "supplyTokenTo(address,uint256)" "$Router1" "5000000000000000000" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Check test contract's balance
cast call "$XToken" "balanceOf(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

# Supply tokens to Router1
cast send "$XToken" "supplyTokenTo(address,uint256)" "$Router1" "2500000000000000000" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Check Router1’s balance
INITIAL_ROUTER1_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

# Check Router2’s balance
INITIAL_ROUTER2_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router2" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

# Approve Router1 for maximum tokens
cast send "$XToken" "approve(address,uint256)" "$Router1" "$(cast --max-uint)" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Approve Router2 for maximum tokens
cast send "$XToken" "approve(address,uint256)" "$Router2" "$(cast --max-uint)" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

# Get token prices from Router1 and Router2
ROUTER1_PRICE=$(cast call "$Router1" "getTokenPrice(address)" "$XToken" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
ROUTER1_PRICE=$(hex2Int "$ROUTER1_PRICE")
ROUTER2_PRICE=$(cast call "$Router2" "getTokenPrice(address)" "$XToken" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
ROUTER2_PRICE=$(hex2Int "$ROUTER2_PRICE")

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

# Check Router1’s balance
FINAL_ROUTER1_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

# Check Router2’s balance
FINAL_ROUTER2_BALANCE=$(cast call "$XToken" "balanceOf(address)" "$Router2" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

echo "Router1's balance: $(hex2Int "$INITIAL_ROUTER1_BALANCE")  -> $(hex2Int "$FINAL_ROUTER1_BALANCE")"
echo "Router2's balance: $(hex2Int "$INITIAL_ROUTER2_BALANCE")  -> $(hex2Int "$FINAL_ROUTER2_BALANCE")"
