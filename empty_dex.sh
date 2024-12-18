#!/bin/bash
set -e
set -x
clear
. ./.env
. ./functions.sh  # Source the external functions

# Check if the provided addresses are valid
for address in "$DEX1" "$DEX2" "$TRASH_CAN" "$WALLET_ADDRESS"; do
    if ! is_valid_address "$address"; then
        echo "Invalid Ethereum address: $address"
        exit 1
    fi
done

echo "Empty DEX"
echo "-------------------------DEX1-------------------------"
# Fetch the balance of $DEX1 in $PIGFOX_TOKEN (in base units)
BALANCE_RAW=$(cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$DEX1" --rpc-url "$SEPOLIA_PUBLIC_NODE")

# Debugging: Print the raw balance to see the format
echo "Raw balance of $DEX1: $BALANCE_RAW"

# Clean up the balance raw result by removing unwanted characters
BALANCE_RAW_CLEAN=$(echo "$BALANCE_RAW" | sed 's/\[.*//g' | sed 's/\]//g' | tr -d '\n' | tr -d ' ')

# Ensure the balance is in hex format and does not contain scientific notation
if [[ "$BALANCE_RAW_CLEAN" =~ "e" ]]; then
    echo "Balance in scientific notation detected. Converting to raw format."
    BALANCE_RAW_CLEAN=$(printf "%.0f" "$BALANCE_RAW_CLEAN")
fi

echo "Cleaned balance of $DEX1: $BALANCE_RAW_CLEAN"

# Convert the balance from hex to decimal using hex2Int
BALANCE_DECIMAL=$(hex2Int "$BALANCE_RAW_CLEAN")

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
    cast send "$PIGFOX_TOKEN" "approve(address,uint256)" "$DEX1" "$BALANCE_RAW_CLEAN" --rpc-url "$SEPOLIA_PUBLIC_NODE" --private-key "$PRIVATE_KEY"
else
    echo "Sufficient allowance for $DEX1"
fi

# Check if balance is greater than zero before transferring
if ! is_greater_than_zero "$BALANCE_DECIMAL"; then
    echo "Balance is zero or invalid. Aborting transfer."
    exit 1
fi

# Transfer tokens from DEX1 to TRASH_CAN
echo "Transferring tokens to $TRASH_CAN"
echo "Attempting to transfer: $BALANCE_RAW_CLEAN to $TRASH_CAN"
TRANSFER_RESULT=$(cast send "$PIGFOX_TOKEN" \
    "transferFrom(address,address,uint256)" \
    "$DEX1" \
    "$TRASH_CAN" \
    "$BALANCE_RAW_CLEAN" \
    --rpc-url "$SEPOLIA_PUBLIC_NODE" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000)  # Increased gas limit

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

# Optionally: Transfer from DEX2 if applicable
if [ "$TRANSFER_DECIMAL" -lt "$BALANCE_DECIMAL" ]; then
    echo "Transferring remaining balance from DEX2 to $TRASH_CAN"
    # Fetch the balance from DEX2 and repeat the transfer process
    BALANCE_RAW_DEX2=$(cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$DEX2" --rpc-url "$SEPOLIA_PUBLIC_NODE")
    BALANCE_RAW_CLEAN_DEX2=$(echo "$BALANCE_RAW_DEX2" | sed 's/\[.*//g' | sed 's/\]//g' | tr -d '\n' | tr -d ' ')

    BALANCE_DECIMAL_DEX2=$(hex2Int "$BALANCE_RAW_CLEAN_DEX2")

    if ! is_greater_than_zero "$BALANCE_DECIMAL_DEX2"; then
        echo "No tokens to transfer from DEX2."
    else
        echo "Transferring tokens from DEX2 to TRASH_CAN"
        cast send "$PIGFOX_TOKEN" "transferFrom(address,address,uint256)" \
            "$DEX2" "$TRASH_CAN" "$BALANCE_RAW_CLEAN_DEX2" \
            --rpc-url "$SEPOLIA_PUBLIC_NODE" --private-key "$PRIVATE_KEY" --gas-limit 200000
    fi
fi

echo "Token transfer complete."
