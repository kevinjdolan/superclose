#!/bin/zsh
#
# install.sh
# One-shot installer for SuperClose. Downloads the release zip from GitHub,
# unpacks SuperClose.app into /Applications, then walks the user through
# assigning a global keyboard shortcut (e.g. ⌃⌥⌘⌫) via Shortcuts.app, since
# macOS does not let scripts register system-wide hotkeys directly. Offers
# to open Shortcuts.app at the end.
#
# Bump VERSION whenever a new release is published — it should match
# MARKETING_VERSION in Config/Project.xcconfig.

set -euo pipefail

VERSION="${SUPERCLOSE_VERSION:-0.1.0}"
REPO="${SUPERCLOSE_REPO:-kevin/superclose}"
ZIP_URL="https://github.com/${REPO}/releases/download/v${VERSION}/SuperClose-${VERSION}.zip"
APP_DIR="/Applications"
APP_NAME="SuperClose.app"

echo "Installing SuperClose ${VERSION} from ${REPO}..."

TMP_ZIP=$(mktemp -t superclose).zip
trap 'rm -f "$TMP_ZIP"' EXIT

curl -fL "$ZIP_URL" -o "$TMP_ZIP"

if [[ -d "$APP_DIR/$APP_NAME" ]]; then
  echo "Removing existing $APP_DIR/$APP_NAME"
  rm -rf "$APP_DIR/$APP_NAME"
fi

ditto -xk "$TMP_ZIP" "$APP_DIR"

if [[ ! -d "$APP_DIR/$APP_NAME" ]]; then
  echo "Install failed: $APP_DIR/$APP_NAME was not created."
  exit 1
fi

echo "Installed $APP_DIR/$APP_NAME"
echo

cat <<'EOF'
Next: assign a global keyboard shortcut
---------------------------------------
macOS does not let installers register system-wide hotkeys, so you will
need to do this once by hand. The easiest path is Shortcuts.app:

  1. Open Shortcuts.app
  2. Click the + button to create a new shortcut
  3. Add the "Open App" action and pick SuperClose
  4. Name the shortcut "SuperClose"
  5. Click the (i) info button → Add Keyboard Shortcut
  6. Press your preferred combo (e.g. ⌃⌥⌘⌫ — Control + Option + Command + Delete)

After that, the chosen combo will launch SuperClose from anywhere.

You can also browse System Settings → Keyboard → Keyboard Shortcuts to
review or change existing shortcuts.
EOF

echo
printf "Open Shortcuts.app now? [Y/n] "
read -r REPLY || REPLY=""
case "$REPLY" in
  ""|y|Y|yes|YES)
    open -a Shortcuts
    ;;
  *)
    echo "Skipping. You can open Shortcuts.app yourself whenever you're ready."
    ;;
esac

echo
printf "Also open System Settings → Keyboard? [y/N] "
read -r REPLY || REPLY=""
case "$REPLY" in
  y|Y|yes|YES)
    open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
    ;;
  *)
    ;;
esac

echo
echo "Done. Launch SuperClose from /Applications, Spotlight, or your new shortcut."
