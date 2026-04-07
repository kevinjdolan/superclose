#!/bin/zsh
#
# generate-cask.sh
# Regenerates packaging/homebrew/superclose.rb for a given release. Takes
# `--version`, `--sha256`, and an optional `--repo owner/name`, and writes a
# cask pointing at the matching GitHub release zip. Called automatically by
# `package-release.sh` when a repo is supplied; can also be run by hand to
# refresh the cask after a manual upload.

set -euo pipefail

ROOT_DIR=${0:A:h:h}
OUTPUT_FILE="$ROOT_DIR/packaging/homebrew/superclose.rb"
VERSION=""
SHA256=""
REPO="kevin/superclose"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --sha256)
      SHA256="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: ./scripts/generate-cask.sh --version x.y.z --sha256 <sha> [--repo owner/name]"
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" || -z "$SHA256" ]]; then
  echo "Both --version and --sha256 are required."
  exit 1
fi

cat > "$OUTPUT_FILE" <<EOF
cask "superclose" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/${REPO}/releases/download/v#{version}/SuperClose-#{version}.zip",
      verified: "github.com/${REPO}/"
  name "SuperClose"
  desc "Bulk hide, quit, and force-quit helper for macOS"
  homepage "https://github.com/${REPO}"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "SuperClose.app"
  binary "superclose"

  zap trash: [
    "~/Library/Preferences/io.github.kevin.superclose.plist",
    "~/Library/Saved Application State/io.github.kevin.superclose.savedState",
  ]
end
EOF

echo "Wrote $OUTPUT_FILE"

