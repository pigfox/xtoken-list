#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
rpc_url="$SEPOLIA_HTTP_RPC_URL"
private_key="$PRIVATE_KEY"

cast send "$ZEPPELIN_PROXY" "setValue(uint256)" 42 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS"  --private-key "$private_key"
#cast call "$ZEPPELIN_PROXY" "value()(uint256)"
#cast send $ZEPPELIN_PROXY "upgradeTo(address)" $ZEPPELIN_IMPL_V2 --from $WALLET_ADDRESS
#cast send $ZEPPELIN_PROXY "initialize(address)" $WALLET_ADDRESS --from $WALLET_ADDRESS
#cast send $ZEPPELIN_PROXY "setValue(uint256)" 100 --from $WALLET_ADDRESS
#cast call $ZEPPELIN_PROXY "value()(uint256)"
#cast call $ZEPPELIN_PROXY "owner()(address)"
#cast call $ZEPPELIN_PROXY "value()(uint256)" --rpc-url "$rpc_url"


