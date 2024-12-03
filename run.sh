#!/bin/sh
set +x
set +e
clear
. ./.env
echo "Running flash loan simulation"
#echo "PRIVATE_KEY: $PRIVATE_KEY"
#echo "SEPOLIA_RPC_URL $SEPOLIA_RPC_URL"
#echo "SEPOLIA_EQUALIZER_LENDER: $SEPOLIA_EQUALIZER_LENDER"
forge clean
forge build --force
#forge test --fork-url http://127.0.0.1:8545 --gas-report --verbosity --match-contract ListTest --match-test test_list -vvvv
#forge create PigfoxToken.sol --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --verify
#forge script script/PigfoxFlashloan.s.sol:PigfoxScript --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify
#forge script script/Dex.sol.s.sol:DexScript --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify
#forge script script/Vault.s.sol:VaultScript --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify
#forge script script/PigfoxToken.sol.s.sol:ERC20TokenScript --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify


#forge test --gas-report --verbosity --match-contract PigfoxTest --match-test test_pigfox -vvvv
forge test --gas-report --verbosity --match-contract PigfoxTest --match-test test_pigfox -vvvv
#forge test --debug test_pigfox -vvvv
