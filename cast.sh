#!/bin/sh
set -x
set -e
clear
. ./.env

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


echo "Calling contracts"
: '
cast call "$Router1" "getName()(string)" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
cast send "$Router1" "setName(string)" "0000000000" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
cast call "$Router1" "getName()(string)" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
$ cast send --private-key <Your Private Key> 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc $(cast from-utf8 "hello world") --rpc-url http://127.0.0.1:8545/
'

cast send "$Router1" "setTokenPrice(address,uint256)" "$XToken" "99998888" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
: '
echo "-----------getTokenPrice--------------"
hex_value=$(cast call "$Router1" "getTokenPrice(address)" "$XToken" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
numerical_value=$(hex2Int "$hex_value")   # Call the function and capture the output
echo "Token Price: $numerical_value"
echo "-----------end getTokenPrice--------------"
: ''
echo "-----------supplyToken--------------"
cast send "$XToken" "supplyToken(address,uint256)" "$Router1" "7878" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --private-key "$PRIVATE_KEY"
echo "-----------end supplyToken--------------"
echo "-----------gas-price--------------"
gas_price=$(cast gas-price --rpc-url "$SEPOLIA_HTTP_RPC_URL")
echo "gas_price $gas_price"
echo "-----------end gas-price--------------"
echo "-----------getBalance--------------"
cast call "$XToken" "getBalance(address)" "$Router1" --rpc-url "$SEPOLIA_HTTP_RPC_URL" #--gas-price "$gas_price"
echo "-----------end getBalance--------------"
echo "XToken address: $XToken"
echo "Router1 address: $Router1"

echo "-----------totalSupply@ $XToken --------------"
hex_value=$(cast call "$XToken" "totalSupply()" --rpc-url "$SEPOLIA_HTTP_RPC_URL")
total_supply=$(hex2Int "$hex_value")
echo "Total supply: $total_supply"
echo "-----------end totalSupply--------------"
'
: '
This is a
very neat comment
in bash
'