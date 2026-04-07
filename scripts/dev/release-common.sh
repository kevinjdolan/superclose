#!/bin/zsh
#
# release-common.sh
# Shared environment and helper functions sourced by the other release
# scripts (archive / notarize / package / generate-cask). Defines build, dist,
# archive, export, and staging paths; reads MARKETING_VERSION and signing
# values out of Config/Project.xcconfig and Config/Signing.local.xcconfig; and
# exposes guards (`ensure_full_xcode`, `require_signing_config`) plus path
# helpers (`release_zip_path`, `release_sha_path`) used during a release.

set -euo pipefail

ROOT_DIR=${0:A:h:h}
PROJECT_FILE="$ROOT_DIR/SuperClose.xcodeproj"
PROJECT_CONFIG="$ROOT_DIR/Config/Project.xcconfig"
SIGNING_CONFIG="$ROOT_DIR/Config/Signing.local.xcconfig"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_PATH="$BUILD_DIR/SuperClose.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
STAGING_DIR="$BUILD_DIR/staging"
SCHEME="SuperClose"
PRODUCT_NAME="SuperClose"
APP_NAME="${PRODUCT_NAME}.app"

function ensure_full_xcode() {
  local selected_path
  selected_path=$(xcode-select -p 2>/dev/null || true)
  if [[ -z "$selected_path" || "$selected_path" == "/Library/Developer/CommandLineTools" ]]; then
    echo "Full Xcode is required. Install /Applications/Xcode.app and run:"
    echo "  sudo xcode-select -s /Applications/Xcode.app"
    exit 1
  fi
}

function require_signing_config() {
  if [[ ! -f "$SIGNING_CONFIG" ]]; then
    echo "Missing $SIGNING_CONFIG"
    echo "Copy Config/Signing.local.xcconfig.example to Config/Signing.local.xcconfig and fill in your values."
    exit 1
  fi
}

function xcconfig_value() {
  local key=$1
  local file=$2
  awk -F '=' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$file"
}

function marketing_version() {
  xcconfig_value "MARKETING_VERSION" "$PROJECT_CONFIG"
}

function team_id() {
  xcconfig_value "DEVELOPMENT_TEAM" "$SIGNING_CONFIG"
}

function developer_id_application() {
  xcconfig_value "DEVELOPER_ID_APPLICATION" "$SIGNING_CONFIG"
}

function notary_profile() {
  xcconfig_value "NOTARY_KEYCHAIN_PROFILE" "$SIGNING_CONFIG"
}

function release_zip_path() {
  local version
  version=$(marketing_version)
  echo "$DIST_DIR/${PRODUCT_NAME}-${version}.zip"
}

function release_sha_path() {
  local version
  version=$(marketing_version)
  echo "$DIST_DIR/${PRODUCT_NAME}-${version}.sha256"
}

function prepare_build_directories() {
  mkdir -p "$BUILD_DIR" "$DIST_DIR"
}

