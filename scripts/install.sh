#!/bin/zsh
#
# install.sh
# One-shot installer for SuperClose. Downloads the release zip from GitHub,
# installs SuperClose.app into /Applications, installs a `superclose` shell
# command, and can optionally wire up a global keyboard shortcut through skhd.
#
# Bump VERSION whenever a new release is published — it should match
# MARKETING_VERSION in Config/Project.xcconfig.

set -euo pipefail

VERSION="${SUPERCLOSE_VERSION:-0.1.0}"
REPO="${SUPERCLOSE_REPO:-kevinjdolan/superclose}"
ZIP_URL="https://github.com/${REPO}/releases/download/v${VERSION}/SuperClose-${VERSION}.zip"
APP_DIR="${SUPERCLOSE_APP_DIR:-/Applications}"
APP_NAME="SuperClose.app"
CLI_NAME="superclose"
SKHDRC_PATH="${SUPERCLOSE_SKHD_CONFIG:-$HOME/.skhdrc}"
TTY_DEVICE="/dev/tty"
HAVE_TTY=0
SHORTCUT_DESCRIPTION="Control + Option + Command + Delete/Backspace"
SHORTCUT_BINDING="cmd + ctrl + alt - backspace"
SKHD_BLOCK_START="# >>> superclose >>>"
SKHD_BLOCK_END="# <<< superclose <<<"

if [[ -r "$TTY_DEVICE" && -w "$TTY_DEVICE" ]]; then
  HAVE_TTY=1
fi

say() {
  print -r -- "$*"
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local reply=""

  while true; do
    if (( HAVE_TTY )); then
      if [[ "$default" == "yes" ]]; then
        printf "%s [Y/n] " "$prompt" >"$TTY_DEVICE"
      else
        printf "%s [y/N] " "$prompt" >"$TTY_DEVICE"
      fi

      IFS= read -r reply <"$TTY_DEVICE" || reply=""
    else
      reply=""
    fi

    reply="${reply:l}"
    case "$reply" in
      "")
        [[ "$default" == "yes" ]] && return 0 || return 1
        ;;
      y|yes)
        return 0
        ;;
      n|no)
        return 1
        ;;
      *)
        say "Please answer y or n."
        ;;
    esac
  done
}

prompt_value() {
  local prompt="$1"
  local default="$2"
  local reply=""

  if (( HAVE_TTY )); then
    printf "%s [%s] " "$prompt" "$default" >"$TTY_DEVICE"
    IFS= read -r reply <"$TTY_DEVICE" || reply=""
  fi

  if [[ -z "$reply" ]]; then
    print -r -- "$default"
  else
    print -r -- "$reply"
  fi
}

path_contains_dir() {
  local candidate="$1"
  [[ ":$PATH:" == *":$candidate:"* ]]
}

default_bin_dir() {
  local candidate
  for candidate in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if path_contains_dir "$candidate"; then
      print -r -- "$candidate"
      return
    fi
  done

  print -r -- "/usr/local/bin"
}

expand_path() {
  local expanded_path="$1"

  if [[ "$expanded_path" == "~"* ]]; then
    expanded_path="${HOME}${expanded_path:1}"
  elif [[ "$expanded_path" != /* ]]; then
    expanded_path="${PWD}/$expanded_path"
  fi

  if [[ "$expanded_path" != "/" ]]; then
    expanded_path="${expanded_path%/}"
  fi

  print -r -- "$expanded_path"
}

ensure_directory() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    return
  fi

  if [[ -w "${dir:h}" ]]; then
    mkdir -p "$dir"
  else
    sudo mkdir -p "$dir"
  fi
}

remove_existing_path() {
  local target_path="$1"

  if [[ ! -e "$target_path" ]]; then
    return
  fi

  if [[ -w "$target_path" || -w "${target_path:h}" ]]; then
    rm -rf "$target_path"
  else
    sudo rm -rf "$target_path"
  fi
}

copy_bundle() {
  local source="$1"
  local target="$2"

  ensure_directory "${target:h}"
  if [[ -w "${target:h}" ]]; then
    ditto "$source" "$target"
  else
    sudo ditto "$source" "$target"
  fi
}

install_executable() {
  local source="$1"
  local target="$2"

  ensure_directory "${target:h}"
  if [[ -w "${target:h}" ]]; then
    install -m 755 "$source" "$target"
  else
    sudo install -m 755 "$source" "$target"
  fi
}

load_homebrew() {
  local brew_bin

  brew_bin=$(command -v brew || true)
  if [[ -n "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
    return 0
  fi

  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  return 1
}

ensure_homebrew() {
  if load_homebrew; then
    return 0
  fi

  say
  say "Homebrew is required to install skhd."
  if ! prompt_yes_no "Install Homebrew now?" yes; then
    say "Skipping shortcut setup because Homebrew is not installed."
    return 1
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! load_homebrew; then
    say "Homebrew installed, but this shell could not find brew afterwards."
    say "Open a new terminal window and rerun the installer to finish shortcut setup."
    exit 1
  fi

  return 0
}

ensure_skhd() {
  if command -v skhd >/dev/null 2>&1; then
    return 0
  fi

  say
  say "Installing skhd via Homebrew..."
  brew tap koekeishiya/formulae
  brew install koekeishiya/formulae/skhd
}

write_skhd_config() {
  local config_path="$1"
  local command_path="$2"
  local escaped_command_path="${(q)command_path}"
  local binding_line="${SHORTCUT_BINDING} : ${escaped_command_path}"
  local tmp_existing
  local tmp_final

  ensure_directory "${config_path:h}"

  tmp_existing=$(mktemp -t superclose-skhdrc-existing)
  tmp_final=$(mktemp -t superclose-skhdrc-final)

  if [[ -f "$config_path" ]]; then
    awk -v start="$SKHD_BLOCK_START" -v end="$SKHD_BLOCK_END" '
      $0 == start { skipping = 1; next }
      $0 == end { skipping = 0; next }
      !skipping { print }
    ' "$config_path" >"$tmp_existing"
  else
    : >"$tmp_existing"
  fi

  {
    cat "$tmp_existing"
    if [[ -s "$tmp_existing" ]]; then
      printf "\n"
    fi
    printf "%s\n" "$SKHD_BLOCK_START"
    printf "# Launch SuperClose from anywhere.\n"
    printf "%s\n" "$binding_line"
    printf "%s\n" "$SKHD_BLOCK_END"
  } >"$tmp_final"

  mv "$tmp_final" "$config_path"
  rm -f "$tmp_existing"
}

restart_skhd_service() {
  if skhd --restart-service >/dev/null 2>&1; then
    return 0
  fi

  skhd --start-service >/dev/null 2>&1
}

command_launch_hint() {
  local command_path="$1"

  if path_contains_dir "${command_path:h}"; then
    print -r -- "by running superclose"
  else
    print -r -- "by running ${command_path}"
  fi
}

say "Installing SuperClose ${VERSION} from ${REPO}..."

TMP_ROOT=$(mktemp -d -t superclose)
TMP_ZIP="$TMP_ROOT/SuperClose-${VERSION}.zip"
STAGING_DIR="$TMP_ROOT/staging"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$STAGING_DIR"
curl -fL "$ZIP_URL" -o "$TMP_ZIP"
ditto -xk "$TMP_ZIP" "$STAGING_DIR"

APP_SOURCE="$STAGING_DIR/$APP_NAME"
CLI_SOURCE="$STAGING_DIR/$CLI_NAME"

if [[ ! -d "$APP_SOURCE" ]]; then
  say "Install failed: ${APP_NAME} was not found in the release zip."
  exit 1
fi

if [[ ! -f "$CLI_SOURCE" ]]; then
  say "Install failed: ${CLI_NAME} was not found in the release zip."
  exit 1
fi

DEFAULT_BIN_DIR=$(default_bin_dir)
BIN_TARGET_INPUT=$(prompt_value "Install the ${CLI_NAME} shell command into which directory?" "$DEFAULT_BIN_DIR")
BIN_TARGET_INPUT=$(expand_path "$BIN_TARGET_INPUT")

if [[ "${BIN_TARGET_INPUT:t}" == "$CLI_NAME" ]]; then
  CLI_TARGET="$BIN_TARGET_INPUT"
else
  CLI_TARGET="$BIN_TARGET_INPUT/$CLI_NAME"
fi

if [[ -d "$APP_DIR/$APP_NAME" ]]; then
  say "Removing existing $APP_DIR/$APP_NAME"
  remove_existing_path "$APP_DIR/$APP_NAME"
fi

copy_bundle "$APP_SOURCE" "$APP_DIR/$APP_NAME"
install_executable "$CLI_SOURCE" "$CLI_TARGET"

say "Installed $APP_DIR/$APP_NAME"
say "Installed $CLI_TARGET"

if ! path_contains_dir "${CLI_TARGET:h}"; then
  say
  say "Note: ${CLI_TARGET:h} is not currently on your PATH."
  say "You can still launch SuperClose by running ${CLI_TARGET} directly."
fi

if ! prompt_yes_no "Add a global ${SHORTCUT_DESCRIPTION} shortcut with skhd?" yes; then
  say
  say "Done. Launch SuperClose from ${APP_DIR}, Spotlight, or $(command_launch_hint "$CLI_TARGET")."
  exit 0
fi

if ! ensure_homebrew; then
  say
  say "Done. Launch SuperClose from ${APP_DIR}, Spotlight, or $(command_launch_hint "$CLI_TARGET")."
  exit 0
fi

ensure_skhd
write_skhd_config "$SKHDRC_PATH" "$CLI_TARGET"
restart_skhd_service

say
say "Shortcut installed in $SKHDRC_PATH:"
say "  $SHORTCUT_BINDING : $CLI_TARGET"
say
say "Try pressing ${SHORTCUT_DESCRIPTION} now."
say "If macOS asks, grant Accessibility access to skhd and then run: skhd --restart-service"
say
say "Done. Launch SuperClose from ${APP_DIR}, Spotlight, or $(command_launch_hint "$CLI_TARGET")."
