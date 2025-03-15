#!/bin/bash
set -e
clear
. ./.env
. ./functions.sh  # Source the external functions

# Function to enable tracing only for `cast` commands
trace_cast_call() {
    set -x
    "$@"
    set +x
}

export $(grep -v '^#' .env | xargs)

# Debugging: Print the environment variables
echo "Environment Variables:"
echo "DEX1=$DEX1"
echo "DEX2=$DEX2"
echo "TRASH_CAN=$TRASH_CAN"
echo "WALLET_ADDRESS=$WALLET_ADDRESS"
echo "SEPOLIA_HTTP_RPC_URL=$SEPOLIA_HTTP_RPC_URL"
echo "PIGFOX_TOKEN=$PIGFOX_TOKEN"

# Check if the provided addresses are valid
for address in "$DEX1" "$DEX2" "$TRASH_CAN"; do
    if ! is_valid_address "$address"; then
        echo "Invalid Ethereum address: $address"
        exit 1
    fi
done

# Function to empty a DEX if balance is greater than zero
empty_dex() {
    local dex=$1
    echo "-------------------------$dex-------------------------"

    # Fetch the balance of the DEX in PIGFOX_TOKEN (in base units)
    BALANCE_RAW=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$dex" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

    # Debugging: Print the raw balance to see the format
    echo "Raw balance of $dex: $BALANCE_RAW"

    # Clean up the balance raw result by removing unwanted characters
    BALANCE_RAW_CLEAN=$(echo "$BALANCE_RAW" | sed 's/\[.*//g' | sed 's/\]//g' | tr -d '\n' | tr -d ' ')

    # Ensure the balance is in hex format and does not contain scientific notation
    if [[ "$BALANCE_RAW_CLEAN" =~ "e" ]]; then
        echo "Balance in scientific notation detected. Converting to raw format."
        BALANCE_RAW_CLEAN=$(printf "%.0f" "$BALANCE_RAW_CLEAN")
    fi

    echo "Cleaned balance of $dex: $BALANCE_RAW_CLEAN"

    # Convert the balance from hex to decimal using hex2Int
    BALANCE_DECIMAL=$(hex2Int "$BALANCE_RAW_CLEAN")

    # Assuming the token has 18 decimals (standard ERC20 token decimals)
    DECIMALS=18

    # Convert the raw balance to human-readable format
    BALANCE_BASE_UNIT=$(echo "scale=$DECIMALS; $BALANCE_DECIMAL / (10 ^ $DECIMALS)" | bc)

    echo "Balance in decimals: $BALANCE_DECIMAL"
    echo "Balance in base units: $BALANCE_BASE_UNIT"

    # Check allowance for the DEX to ensure it has permission to transfer the tokens
    ALLOWANCE_RAW=$(trace_cast_call cast call "$PIGFOX_TOKEN" "allowance(address,address)(uint256)" "$WALLET_ADDRESS" "$dex" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    ALLOWANCE_RAW_HEX=$(echo "$ALLOWANCE_RAW" | awk '{print $1}')
    ALLOWANCE_DECIMAL=$(hex2Int "$ALLOWANCE_RAW_HEX")

    echo "Allowance for $dex: $ALLOWANCE_DECIMAL"

    # Ensure sufficient allowance for the DEX
    ALLOWANCE_LESS_THAN_BALANCE=$(echo "$ALLOWANCE_DECIMAL < $BALANCE_DECIMAL" | bc)

    if [ "$ALLOWANCE_LESS_THAN_BALANCE" -eq 1 ]; then
        echo "Insufficient allowance, approving full balance for $dex"
        trace_cast_call cast send "$PIGFOX_TOKEN" "approve(address,uint256)" "$dex" "$BALANCE_RAW_CLEAN" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
    else
        echo "Sufficient allowance for $dex"
    fi

    # Check if balance is greater than zero before transferring
    if ! is_greater_than_zero "$BALANCE_DECIMAL"; then
        echo "Balance is zero or invalid. Skipping transfer."
        return  # Skip this DEX if balance is zero
    fi

    trace_cast_call cast send "$dex" "approveTokenTransfer(address,address,uint256)" "$PIGFOX_TOKEN" "$WALLET_ADDRESS" "$BALANCE_RAW_CLEAN" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"

    # Transfer tokens from DEX to TRASH_CAN
    echo "Transferring tokens to $TRASH_CAN"
    echo "Attempting to transfer: $BALANCE_RAW_CLEAN to $TRASH_CAN"
    TRANSFER_RESULT=$(trace_cast_call cast send "$PIGFOX_TOKEN" \
        "transferFrom(address,address,uint256)" \
        "$dex" \
        "$TRASH_CAN" \
        "$BALANCE_RAW_CLEAN" \
        --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --gas-limit 200000)  # Increased gas limit

    # Check for errors in the transfer result
    if [ $? -ne 0 ]; then
        echo "Error during transfer. Transaction failed with revert."
        exit 1
    fi

    # Check new balance of $TRASH_CAN
    TRANSFER_RESULT=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$TRASH_CAN" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    TRANSFER_RAW_HEX=$(echo "$TRANSFER_RESULT" | awk '{print $1}')
    TRANSFER_DECIMAL=$(hex2Int "$TRANSFER_RAW_HEX")
    echo "New balance of $TRASH_CAN: $TRANSFER_DECIMAL"
}

# Empty DEX1 if balance is greater than zero
echo "Empty DEX1 if balance is greater than zero"
empty_dex "$DEX1"

# Empty DEX2 if balance is greater than zero (This will be executed even if DEX1 has zero balance)
echo "Empty DEX2 if balance is greater than zero"
empty_dex "$DEX2"

echo "Token transfer complete."
