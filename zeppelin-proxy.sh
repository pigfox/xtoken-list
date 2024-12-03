#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
rpc_url="$SEPOLIA_HTTP_RPC_URL"
private_key="$PRIVATE_KEY"
wallet_address="$WALLET_ADDRESS"

#cast call "$ZEPPELIN_PROXY_HELPER" "getAdmin(address)" "$ZEPPELIN_PROXY" --rpc-url "$rpc_url"
cast call "$ZEPPELIN_PROXY_HELPER" "getImplementation(address)" "$ZEPPELIN_PROXY" --rpc-url "$rpc_url"
#cast send "$ZEPPELIN_PROXY_HELPER" "upgradeTo(address)" "$ZEPPELIN_IMPL_V2" --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"


#cast call "$ZEPPELIN_PROXY" "admin()(address)" --rpc-url "$rpc_url"

#cast call "$ZEPPELIN_PROXY" "implementation()(address)" --rpc-url "$rpc_url" --from "$wallet_address" --private-key "$private_key"

#cast call "$ZEPPELIN_PROXY" "value()(uint256)"
#cast send $ZEPPELIN_PROXY "upgradeTo(address)" $ZEPPELIN_IMPL_V2 --from $WALLET_ADDRESS
#cast send $ZEPPELIN_PROXY "initialize(address)" $WALLET_ADDRESS --from $WALLET_ADDRESS
#cast send $ZEPPELIN_PROXY "setValue(uint256)" 100 --from $WALLET_ADDRESS
#cast call $ZEPPELIN_PROXY "value()(uint256)"
#cast call $ZEPPELIN_PROXY "owner()(address)"
#cast call $ZEPPELIN_PROXY "value()(uint256)" --rpc-url "$rpc_url"


