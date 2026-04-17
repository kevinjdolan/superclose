#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/release-common.sh"

ensure_full_xcode
require_signing_config
prepare_build_directories

APP_PATH="${EXPORT_PATH}/${APP_NAME}"
NOTARY_PROFILE=$(notary_profile)
NOTARY_ZIP="${BUILD_DIR}/notary/${PRODUCT_NAME}.zip"

mkdir -p "${BUILD_DIR}/notary"

if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "NOTARY_KEYCHAIN_PROFILE must be set in $SIGNING_CONFIG"
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle at $APP_PATH"
  echo "Run ./scripts/archive-release.sh first."
  exit 1
fi

rm -f "$NOTARY_ZIP"
ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"

xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "Notarized and stapled $APP_PATH"
