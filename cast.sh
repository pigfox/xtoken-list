#!/bin/sh
set +x
set +e
clear
. ./.env
echo "Calling contract"
#cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL"
#cast send "$Dex1" "setName(string)" "0000000000" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
#cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL"
#$ cast send --private-key <Your Private Key> 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc $(cast from-utf8 "hello world") --rpc-url http://127.0.0.1:8545/
cast send "$Dex1" "setTokenPrice(address,uint256)" "$ERC20Token" "66669" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
echo "-------------------------"
hex_value=$(cast call "$Dex1" "getTokenPrice(address)" "$ERC20Token" --rpc-url "$SEPOLIA_RPC_URL")

# Clean the output by stripping '0x' and any extra whitespace
hex_value=$(echo "$hex_value" | sed 's/^0x//' | tr -d '\n' | tr -d ' ')

# Check if the value is not empty and valid for conversion
if [ -z "$hex_value" ]; then
    echo "Error: hex_value is empty"
else
    # Use printf to convert the large hex value to decimal
    decimal_value=$(printf "%d\n" "0x$hex_value")
    echo "Decimal value: $decimal_value"
fi