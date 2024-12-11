#!/bin/sh
set -e
clear
. ./.env
. ./hex2Int.sh  # Source the external file containing hex2Int

echo "Empty DEX"

# Fetch the balance of $DEX1 in $PIGFOX_TOKEN (in base units)
BALANCE_RAW=$(cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$DEX1" --rpc-url "$SEPOLIA_PUBLIC_NODE")
echo "Balance of $DEX1: $BALANCE_RAW"

# Remove any non-hexadecimal parts like scientific notation
BALANCE_RAW_HEX=$(echo "$BALANCE_RAW" | cut -d ' ' -f 1)
echo "Balance of $DEX1 (Hex): $BALANCE_RAW_HEX"

# Convert the balance from hex to decimal using hex2Int
BALANCE_DECIMAL=$(hex2Int "$BALANCE_RAW_HEX")

# Assuming the token has 18 decimals (standard ERC20 token decimals)
DECIMALS=18

# Convert the raw balance to human-readable format
BALANCE_BASE_UNIT=$(echo "scale=$DECIMALS; $BALANCE_DECIMAL / (10 ^ $DECIMALS)" | bc)

echo "Balance in decimals: $BALANCE_DECIMAL"
echo "Balance in base units: $BALANCE_BASE_UNIT"

# Verify if $DEX1 has the correct approval
ALLOWANCE_RAW=$(cast call "$PIGFOX_TOKEN" "allowance(address,address)(uint256)" "$WALLET_ADDRESS" "$DEX1" --rpc-url "$SEPOLIA_PUBLIC_NODE")
ALLOWANCE_RAW_HEX=$(echo "$ALLOWANCE_RAW" | awk '{print $1}')
ALLOWANCE_DECIMAL=$(hex2Int "$ALLOWANCE_RAW_HEX")

echo "Allowance for $DEX1: $ALLOWANCE_DECIMAL"

# Use bc to compare large numbers
ALLOWANCE_LESS_THAN_BALANCE=$(echo "$ALLOWANCE_DECIMAL < $BALANCE_DECIMAL" | bc)

if [ "$ALLOWANCE_LESS_THAN_BALANCE" -eq 1 ]; then
    echo "Insufficient allowance, approving full balance for $DEX1"
    cast send "$PIGFOX_TOKEN" "approve(address,uint256)" "$DEX1" "$BALANCE_RAW" --rpc-url "$SEPOLIA_PUBLIC_NODE" --private-key "$PRIVATE_KEY"
else
    echo "Sufficient allowance for $DEX1"
fi

# Transfer tokens to $TRASH_CAN
echo "Transferring tokens to $TRASH_CAN"
TRANSFER_RESULT=$(cast send "$PIGFOX_TOKEN" \
    "transfer(address,uint256)" \
    "$TRASH_CAN" \
    "$BALANCE_RAW_HEX" \
    --rpc-url "$SEPOLIA_PUBLIC_NODE" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 100000)  # Increase gas limit if needed

# Check for errors in the transfer result
if [ $? -ne 0 ]; then
    echo "Error during transfer. Transaction failed with revert."
    exit 1
fi

# Check new balance of $TRASH_CAN
TRANSFER_RESULT=$(cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$TRASH_CAN" --rpc-url "$SEPOLIA_PUBLIC_NODE")
TRANSFER_RAW_HEX=$(echo "$TRANSFER_RESULT" | awk '{print $1}')
TRANSFER_DECIMAL=$(hex2Int "$TRANSFER_RAW_HEX")
echo "New balance of $TRASH_CAN: $TRANSFER_DECIMAL"
