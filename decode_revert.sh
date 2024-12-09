#!/bin/bash

#server returned an error response: error code 3: execution reverted,
# data: "0xe450d38c000000000000000000000000b04d6a4949fa623629e0ed6bd4ecb78a8c84769300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000"
# Input: Error data
data="0xfb8f41b200000000000000000000000097f8e44a0437dc4e422683fedddaa45be9dd1ac900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000"

# Set RPC URL for Sepolia
export ETH_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"

# Extract the signature (first 4 bytes) and parameters
signature="${data:0:10}"
params="${data:10}"

echo "Signature: $signature"
echo "Parameters: $params"

# Decode the signature using `cast`
echo "Decoding signature..."
cast 4byte "$signature"

# Decode the parameters
param1="0x${params:24:40}" # Address (20 bytes, offset by 12 bytes padding)
param2="0x${params:104:64}" # Uint256 (balance)
param3="0x${params:168:64}" # Uint256 (amount)

# Debug extracted parameters
echo "Extracted Parameter 1 (Address): $param1"
echo "Extracted Parameter 2 (Balance): $param2"
echo "Extracted Parameter 3 (Amount): $param3"

# Decode using `cast`
echo "Parameter 1 (Address): $(cast to-checksum "$param1")"
echo "Parameter 2 (Uint256, Balance): $(cast --to-dec "$param2")"
echo "Parameter 3 (Uint256, Amount): $(cast --to-dec "$param3")"
