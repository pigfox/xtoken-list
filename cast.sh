#!/bin/sh
set +x
set +e
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
cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL"
cast send "$Dex1" "setName(string)" "0000000000" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL"
$ cast send --private-key <Your Private Key> 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc $(cast from-utf8 "hello world") --rpc-url http://127.0.0.1:8545/
'
cast send "$Dex1" "setTokenPrice(address,uint256)" "$ERC20Token" "1000" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
echo "-----------getTokenPrice--------------"
hex_value=$(cast call "$Dex1" "getTokenPrice(address)" "$ERC20Token" --rpc-url "$SEPOLIA_RPC_URL")
numerical_value=$(hex2Int "$hex_value")   # Call the function and capture the output
echo "Token Price: $numerical_value"
echo "-----------end getTokenPrice--------------"
: ''
echo "-----------supplyToken--------------"
cast send "$ERC20Token" "supplyToken(address,uint256)" "$Dex1" "7878" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
echo "-----------end supplyToken--------------"
echo "-----------gas-price--------------"
gas_price=$(cast gas-price --rpc-url "$SEPOLIA_RPC_URL")
echo "gas_price $gas_price"
echo "-----------end gas-price--------------"
echo "-----------getBalance--------------"
cast call "$ERC20Token" "getBalance(address)" "$Dex1" --rpc-url "$SEPOLIA_RPC_URL" #--gas-price "$gas_price"
echo "-----------end getBalance--------------"
echo "ERC20Token address: $ERC20Token"
echo "Dex1 address: $Dex1"

echo "-----------totalSupply@ $ERC20Token --------------"
hex_value=$(cast call "$ERC20Token" "totalSupply()" --rpc-url "$SEPOLIA_RPC_URL")
total_supply=$(hex2Int "$hex_value")
echo "Total supply: $total_supply"
echo "-----------end totalSupply--------------"

: '
This is a
very neat comment
in bash
'