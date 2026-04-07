#!/bin/zsh
#
# package-release.sh
# Top-level release driver. Runs `archive-release.sh`, optionally
# `notarize-release.sh` (skipped with `--skip-notarization`), then stages
# SuperClose.app alongside the `superclose` CLI wrapper, zips them into
# dist/SuperClose-<version>.zip, and writes the matching .sha256. If a
# `--repo owner/name` (or `GITHUB_REPOSITORY`) is supplied, it also calls
# `generate-cask.sh` to refresh the Homebrew cask with the new version
# and checksum.

set -euo pipefail

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/release-common.sh"

SKIP_NOTARIZATION=0
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-notarization)
      SKIP_NOTARIZATION=1
      shift
      ;;
    --repo)
      GITHUB_REPOSITORY="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: ./scripts/package-release.sh [--skip-notarization] [--repo owner/name]"
      exit 1
      ;;
  esac
done

prepare_build_directories
"$SCRIPT_DIR/archive-release.sh"

if [[ "$SKIP_NOTARIZATION" -eq 0 ]]; then
  "$SCRIPT_DIR/notarize-release.sh"
fi

APP_PATH="${EXPORT_PATH}/${APP_NAME}"
ZIP_PATH=$(release_zip_path)
SHA_PATH=$(release_sha_path)
VERSION=$(marketing_version)

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/$APP_NAME"
cp "$SCRIPT_DIR/superclose" "$STAGING_DIR/superclose"

rm -f "$ZIP_PATH" "$SHA_PATH"
(cd "$STAGING_DIR" && ditto -c -k --keepParent "$APP_NAME" "$ZIP_PATH.tmp")
(cd "$STAGING_DIR" && zip -qry "$ZIP_PATH" "$APP_NAME" superclose)
rm -f "$ZIP_PATH.tmp"

shasum -a 256 "$ZIP_PATH" > "$SHA_PATH"

if [[ -n "$GITHUB_REPOSITORY" ]]; then
  SHA256=$(cut -d' ' -f1 "$SHA_PATH")
  "$SCRIPT_DIR/generate-cask.sh" --version "$VERSION" --sha256 "$SHA256" --repo "$GITHUB_REPOSITORY"
fi

echo "Packaged $ZIP_PATH"
echo "SHA256 written to $SHA_PATH"

