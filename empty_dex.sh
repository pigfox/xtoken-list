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

trap 'echo "Error at line $LINENO"; exit 1' ERR

export $(grep -v '^#' .env | xargs)

# Debugging: Print the environment variables
echo "Environment Variables:"
echo "DEX1=$DEX1"
echo "DEX2=$DEX2"
echo "BURN_ADDRESS=$BURN_ADDRESS"
echo "WALLET_ADDRESS=$WALLET_ADDRESS"
echo "SEPOLIA_HTTP_RPC_URL=$SEPOLIA_HTTP_RPC_URL"
echo "PIGFOX_TOKEN=$PIGFOX_TOKEN"

# Check if the provided addresses are valid
for address in "$DEX1" "$DEX2" "$BURN_ADDRESS"; do
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
    BALANCE_RAW=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$dex" --rpc-url "$SEPOLIA_HTTP_RPC_URL")

    echo "Raw balance of $dex: $BALANCE_RAW"

    # Clean up the balance raw result
    BALANCE_RAW_CLEAN=$(echo "$BALANCE_RAW" | sed 's/\[.*//g' | sed 's/\]//g' | tr -d '\n' | tr -d ' ')

    if [[ "$BALANCE_RAW_CLEAN" =~ "e" ]]; then
        echo "Balance in scientific notation detected. Converting to raw format."
        BALANCE_RAW_CLEAN=$(printf "%.0f" "$BALANCE_RAW_CLEAN")
    fi

    echo "Cleaned balance of $dex: $BALANCE_RAW_CLEAN"

    # Convert the balance from hex to decimal
    BALANCE_DECIMAL=$(hex2Int "$BALANCE_RAW_CLEAN")
    DECIMALS=18
    BALANCE_BASE_UNIT=$(echo "scale=$DECIMALS; $BALANCE_DECIMAL / (10 ^ $DECIMALS)" | bc)

    echo "Balance in decimals: $BALANCE_DECIMAL"
    echo "Balance in base units: $BALANCE_BASE_UNIT"

    # Check if balance is greater than zero
    if ! is_greater_than_zero "$BALANCE_DECIMAL"; then
        echo "Balance is zero or invalid. Skipping transfer."
        return
    fi

    # Withdraw tokens from DEX to WALLET_ADDRESS (assuming simpler withdraw function)
    echo "Withdrawing $BALANCE_BASE_UNIT tokens from $dex to $WALLET_ADDRESS"
    WITHDRAW_RESULT=$(trace_cast_call cast send "$dex" \
        "withdraw(address,uint256)" \
        "$PIGFOX_TOKEN" \
        "$BALANCE_RAW_CLEAN" \
        --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --gas-limit 200000 \
        --json)

    # Extract transaction hash and check status
    WITHDRAW_TX_HASH=$(echo "$WITHDRAW_RESULT" | jq -r '.transactionHash')
    if [ -z "$WITHDRAW_TX_HASH" ] || [ "$WITHDRAW_TX_HASH" == "null" ]; then
        echo "Error during withdrawal. Transaction failed or reverted."
        echo "Withdraw result: $WITHDRAW_RESULT"
        exit 1
    fi
    echo "Withdrawal Tx Hash: $WITHDRAW_TX_HASH"

    # Transfer from wallet to BURN_ADDRESS
    echo "Transferring $BALANCE_BASE_UNIT tokens from $WALLET_ADDRESS to $BURN_ADDRESS"
    TRANSFER_RESULT=$(trace_cast_call cast send "$PIGFOX_TOKEN" \
        "transfer(address,uint256)" \
        "$BURN_ADDRESS" \
        "$BALANCE_RAW_CLEAN" \
        --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --gas-limit 200000 \
        --json)

    TRANSFER_TX_HASH=$(echo "$TRANSFER_RESULT" | jq -r '.transactionHash')
    if [ -z "$TRANSFER_TX_HASH" ] || [ "$TRANSFER_TX_HASH" == "null" ]; then
        echo "Error during transfer to burn address. Transaction failed or reverted."
        echo "Transfer result: $TRANSFER_RESULT"
        exit 1
    fi
    echo "Transfer Tx Hash: $TRANSFER_TX_HASH"

    # Check new balance of $BURN_ADDRESS
    TRANSFER_RESULT=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$BURN_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    TRANSFER_RAW_HEX=$(echo "$TRANSFER_RESULT" | awk '{print $1}')
    TRANSFER_DECIMAL=$(hex2Int "$TRANSFER_RAW_HEX")
    echo "New balance of $BURN_ADDRESS: $TRANSFER_DECIMAL"
}

# Empty DEX1 if balance is greater than zero
echo "Empty DEX1 if balance is greater than zero"
empty_dex "$DEX1"

# Empty DEX2 if balance is greater than zero
echo "Empty DEX2 if balance is greater than zero"
empty_dex "$DEX2"

echo "Token transfer complete."