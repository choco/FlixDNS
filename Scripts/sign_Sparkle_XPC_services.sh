#!/bin/bash

sign_xpc="$SOURCE_ROOT/Vendor/Sparkle/bin/codesign_xpc"
developer_identity=$CODE_SIGN_IDENTITY
xpc_services_dir="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/XPCServices"
for sparkle_xpc_service in $xpc_services_dir/org.sparkle-project.*.xpc; do
    $sign_xpc "$developer_identity" "$sparkle_xpc_service"
done
