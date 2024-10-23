#!/bin/sh
set +x
set +e
clear
. ./.env

contract="ERC20Token"
forge script script/"$ERC20Token".s.sol:"$ERC20Token"Script --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify