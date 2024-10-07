#!/bin/sh
set +x
set +e
source .env 
clear
echo "Running flash loan simulation"
echo "PRIVATE_KEY: $PRIVATE_KEY"
echo "SEPOLIA_RPC_URL $SEPOLIA_RPC_URL"
echo "line 9"
cat .env
forge clean
forge build --force
#forge test --fork-url http://127.0.0.1:8545 --gas-report --verbosity --match-contract ListTest --match-test test_list -vvvv
forge create ERC20Token --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --verify
forge test --gas-report --verbosity --match-contract PigfoxTest --match-test test_pigfox -vvvv

#$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>