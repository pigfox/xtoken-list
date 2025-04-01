#!/bin/bash
set -e  # Exit on error

clear
forge clean
. ./.env  # Load environment variables (SEPOLIA_HTTP_RPC_URL, PRIVATE_KEY, etc.)

# Define contract and new profit address
dex_address="0x4435544600000000000000000000000000000000"  # Replace with actual Arbitrage contract address
new_profit_address="0x8787878700000000000000000000000000000000"  # Replace with desired profit address

# Ensure required env variables are set
if [ -z "$PRIVATE_KEY" ] || [ -z "$SEPOLIA_HTTP_RPC_URL" ]; then
    echo "Error: PRIVATE_KEY or SEPOLIA_HTTP_RPC_URL not set in .env"
    exit 1
fi

# Function to get profit address
get_profit_address() {
    cast call "$dex_address" "profitAddress()" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
}

# Echo current profit address
echo "Fetching current profit address for Arbitrage contract at $dex_address..."
current_profit_address=$(get_profit_address)
echo "Current profit address: $current_profit_address"

# Update profit address
echo "Updating profit address to $new_profit_address..."
cast send "$dex_address" "setProfitAddress(address)" "$new_profit_address" \
    --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000  # Adjust gas limit as needed

# Echo new profit address and verify
echo "Verifying updated profit address..."
updated_profit_address=$(get_profit_address)
echo "Updated profit address: $updated_profit_address"

# Check if the update was successful
if [ "${updated_profit_address,,}" == "${new_profit_address,,}" ]; then
    echo "Success: Profit address updated to $new_profit_address"
else
    echo "Error: Profit address update failed. Expected $new_profit_address, got $updated_profit_address"
    exit 1
fi

echo "Script completed."