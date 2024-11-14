#!/bin/sh
clear
set +x
set -e
json='{"status":"0x1","cumulativeGasUsed":"0xddca03","logs":[{"address":"0xbc35bd49d5de2929522e5cc3f40460d74d24c24c","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000000000000000000000000000000000000000000000","0x000000000000000000000000b04d6a4949fa623629e0ed6bd4ecb78a8c847693"],"data":"0x0000000000000000000000000000000000000000000000000de0b6b3a7640000","blockHash":"0x96a252019d8447e86b34d8883c8fc1037c64656a156f5c6643fe2c7dcb2f89cb","blockNumber":"0x6be443","transactionHash":"0x13c84e6285c893e74bbc19f88cf1deff385789d34151e3d8065db9cfa8e8a7bf","transactionIndex":"0x40","logIndex":"0x5e","removed":false},{"address":"0xbc35bd49d5de2929522e5cc3f40460d74d24c24c","topics":["0xb9203d657e9c0ec8274c818292ab0f58b04e1970050716891770eb1bab5d655e"],"data":"0x0000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000b04d6a4949fa623629e0ed6bd4ecb78a8c847693","blockHash":"0x96a252019d8447e86b34d8883c8fc1037c64656a156f5c6643fe2c7dcb2f89cb","blockNumber":"0x6be443","transactionHash":"0x13c84e6285c893e74bbc19f88cf1deff385789d34151e3d8065db9cfa8e8a7bf","transactionIndex":"0x40","logIndex":"0x5f","removed":false}],"logsBloom":"0x00000000000000000000000000000000000004000000000000000000000000000000000000008400000000000000000000000000000000000000008008000000000000000000000000000008000000000000000000000000000000004000000000000000020000000000000000000800000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000000000000000000008000020000000000000000000000000000000000000000000000000000000000000004000","type":"0x2","transactionHash":"0x13c84e6285c893e74bbc19f88cf1deff385789d34151e3d8065db9cfa8e8a7bf","transactionIndex":"0x40","blockHash":"0x96a252019d8447e86b34d8883c8fc1037c64656a156f5c6643fe2c7dcb2f89cb","blockNumber":"0x6be443","gasUsed":"0x9160","effectiveGasPrice":"0xecf82d4","from":"0xb04d6a4949fa623629e0ed6bd4ecb78a8c847693","to":"0xbc35bd49d5de2929522e5cc3f40460d74d24c24c","contractAddress":null}'

# Extract the status and transactionHash from the JSON using jq
status=$(echo $json | jq -r '.status')
transactionHash=$(echo $json | jq -r '.logs[0].transactionHash')

# Print the extracted values
echo "Status: $status"
echo "Transaction Hash: $transactionHash"