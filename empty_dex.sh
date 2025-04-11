#!/bin/bash
set -e
clear
. ./.env

echo "---------------BEGIN RESET-------------------"
# Function to enable tracing only for `cast` commands
trace_cast_call() {
    set -x
    "$@"
    set +x
}

# Check if an address is a valid Ethereum address (basic check: 42 chars, starts with 0x)
is_valid_address() {
    local addr=$1
    if [[ "$addr" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        return 0 # Valid
    else
        return 1 # Invalid
    fi
}

# Check if a number is greater than zero (handles large integers)
is_greater_than_zero() {
    local num=$1
    if [[ -n "$num" && "$num" =~ ^[0-9]+$ && $(echo "$num > 0" | bc) -eq 1 ]]; then
        return 0 # True
    else
        echo "failed number: $num"
        return 1 # False
    fi
}

trap 'echo "Error at line $LINENO"; exit 1' ERR

export $(grep -v '^#' .env | xargs)

echo "Environment Variables:"
echo "DEX1=$DEX1"
echo "DEX2=$DEX2"
echo "BURN_ADDRESS=$BURN_ADDRESS"
echo "WALLET_ADDRESS=$WALLET_ADDRESS"
echo "SEPOLIA_HTTP_RPC_URL=$SEPOLIA_HTTP_RPC_URL"
echo "PIGFOX_TOKEN=$PIGFOX_TOKEN"

for address in "$DEX1" "$DEX2" "$BURN_ADDRESS"; do
    if ! is_valid_address "$address"; then
        echo "Invalid Ethereum address: $address"
        exit 1
    fi
done

empty_dex() {
    local dex=$1
    echo "-------------------------$dex-------------------------"

    BALANCE_RAW=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$dex" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    echo "Raw balance of $dex: $BALANCE_RAW"

    # Validate BALANCE_RAW
    if [[ -z "$BALANCE_RAW" || ! "$BALANCE_RAW" =~ ^0x[0-9a-fA-F]+$ ]]; then
        echo "Error: Invalid or empty balance returned for $dex"
        echo "Balance is zero or invalid. Skipping transfer."
        return
    fi

    BALANCE_HEX=$(echo "$BALANCE_RAW" | tr -d '[:space:]')
    BALANCE_DECIMAL=$(cast to-dec "$BALANCE_HEX") # Use cast to convert hex to decimal
    if [[ -z "$BALANCE_DECIMAL" || ! "$BALANCE_DECIMAL" =~ ^[0-9]+$ ]]; then
        echo "Error: Failed to convert balance to decimal for $dex: $BALANCE_HEX"
        echo "Balance is zero or invalid. Skipping transfer."
        return
    fi

    DECIMALS=18
    BALANCE_BASE_UNIT=$(echo "scale=$DECIMALS; $BALANCE_DECIMAL / (10 ^ $DECIMALS)" | bc)

    echo "Balance in decimals: $BALANCE_DECIMAL"
    echo "Balance in base units: $BALANCE_BASE_UNIT"

    if ! is_greater_than_zero "$BALANCE_DECIMAL"; then
        echo "Balance is zero or invalid. Skipping transfer."
        return
    fi

    echo "Withdrawing $BALANCE_BASE_UNIT tokens from $dex to $WALLET_ADDRESS"
    WITHDRAW_RESULT=$(trace_cast_call cast send "$dex" \
        "withdraw(address,uint256)" \
        "$PIGFOX_TOKEN" \
        "$BALANCE_DECIMAL" \
        --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
        --private-key "$WALLET_PRIVATE_KEY" \
        --gas-limit 200000 \
        --json)
    WITHDRAW_TX_HASH=$(echo "$WITHDRAW_RESULT" | jq -r '.transactionHash')
    if [ -z "$WITHDRAW_TX_HASH" ] || [ "$WITHDRAW_TX_HASH" == "null" ]; then
        echo "Error during withdrawal: $WITHDRAW_RESULT"
        exit 1
    fi
    echo "Withdrawal Tx Hash: $WITHDRAW_TX_HASH"

    echo "Transferring $BALANCE_BASE_UNIT tokens to $BURN_ADDRESS"
    TRANSFER_RESULT=$(trace_cast_call cast send "$PIGFOX_TOKEN" \
        "transfer(address,uint256)" \
        "$BURN_ADDRESS" \
        "$BALANCE_DECIMAL" \
        --rpc-url "$SEPOLIA_HTTP_RPC_URL" \
        --private-key "$WALLET_PRIVATE_KEY" \
        --gas-limit 200000 \
        --json)
    TRANSFER_TX_HASH=$(echo "$TRANSFER_RESULT" | jq -r '.transactionHash')
    if [ -z "$TRANSFER_TX_HASH" ] || [ "$TRANSFER_TX_HASH" == "null" ]; then
        echo "Error during transfer: $TRANSFER_RESULT"
        exit 1
    fi
    echo "Transfer Tx Hash: $TRANSFER_TX_HASH"

    NEW_BALANCE=$(trace_cast_call cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$BURN_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
    if [[ -z "$NEW_BALANCE" || ! "$NEW_BALANCE" =~ ^0x[0-9a-fA-F]+$ ]]; then
        echo "Warning: Invalid or empty new balance for $BURN_ADDRESS: $NEW_BALANCE"
        echo "Skipping new balance display."
        return
    fi

    NEW_BALANCE_DEC=$(cast to-dec "$NEW_BALANCE")
    if [[ -z "$NEW_BALANCE_DEC" || ! "$NEW_BALANCE_DEC" =~ ^[0-9]+$ ]]; then
        echo "Warning: Failed to convert new balance to decimal for $BURN_ADDRESS: $NEW_BALANCE"
        echo "Skipping new balance display."
        return
    fi
    echo "New balance of $BURN_ADDRESS: $NEW_BALANCE_DEC"
}

echo "Empty DEX1 if balance is greater than zero"
empty_dex "$DEX1"

echo "Empty DEX2 if balance is greater than zero"
empty_dex "$DEX2"

echo "Token transfer complete."
echo "---------------END RESET-------------------"