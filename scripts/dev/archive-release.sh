#!/bin/zsh
#
# archive-release.sh
# Builds a signed Release archive of SuperClose.app and exports it for
# notarization. Generates an ExportOptions.plist from the Developer ID values
# in Config/Signing.local.xcconfig, then runs `xcodebuild archive` followed
# by `xcodebuild -exportArchive` so the resulting bundle lands at
# build/export/SuperClose.app, ready for `notarize-release.sh`.

set -euo pipefail

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/release-common.sh"

ensure_full_xcode
require_signing_config
prepare_build_directories

TEAM_ID=$(team_id)
DEVELOPER_ID=$(developer_id_application)

if [[ -z "$TEAM_ID" || -z "$DEVELOPER_ID" ]]; then
  echo "DEVELOPMENT_TEAM and DEVELOPER_ID_APPLICATION must be set in $SIGNING_CONFIG"
  exit 1
fi

EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"

cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingCertificate</key>
  <string>${DEVELOPER_ID}</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
</dict>
</plist>
EOF

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=macOS" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "Archived and exported $EXPORT_PATH/$APP_NAME"

