#!/usr/bin/env bash

# NOTE: Executed by Xcode in Run script phase

set -o errexit
set -o nounset

sign_xpc="$SOURCE_ROOT/Vendor/Sparkle/bin/codesign_xpc"
developer_identity=$CODE_SIGN_IDENTITY
xpc_services_dir="$BUILT_PRODUCTS_DIR/$XPCSERVICES_FOLDER_PATH"

for sparkle_xpc_service in $xpc_services_dir/org.sparkle-project.*.xpc; do
    $sign_xpc "$developer_identity" "$sparkle_xpc_service"
done
