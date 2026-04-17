# SuperClose

SuperClose is a native macOS utility that makes it easy to clean up your workspace by hiding, quitting, or force-quitting many apps at once from one fast review window.

"Sometimes you just got too many windows open." -Ancient Kevin Proverb

- Scans the currently open applications that actually have windows worth dealing with
- Lets you bulk apply `Ignore`, `Hide`, `Quit`, or `Kill`
- Makes initial heuristic recommendations for default action
- Supports keyboard shortcuts for fast execution

## Install

### Shell Install

```sh
curl -fsSL https://raw.githubusercontent.com/kevinjdolan/superclose/main/scripts/install.sh | zsh
```

The script downloads SuperClose 0.1.0 from GitHub Releases, installs it into `/Applications`, prompts for where to install the `superclose` shell command, and can optionally wire up a global shortcut (default: `⌃⌥⌘⌫`) through `skhd`. If Homebrew or `skhd` are missing, it will offer to install them, update `~/.skhdrc`, and restart the `skhd` service for you.

The pinned version in [scripts/install.sh](/Users/kevin/code/superclose/scripts/install.sh) tracks `MARKETING_VERSION` in [Config/Project.xcconfig](/Users/kevin/code/superclose/Config/Project.xcconfig) — bump both together when cutting a release. To install a different version, set `SUPERCLOSE_VERSION=x.y.z` before running the script.

### Homebrew

The maintained cask lives at [packaging/homebrew/superclose.rb](/Users/kevin/code/superclose/packaging/homebrew/superclose.rb). Upstream submission instructions live in [docs/brew-cask-submission.md](/Users/kevin/code/superclose/docs/brew-cask-submission.md).

## Usage

Launch SuperClose from `/Applications`, Spotlight, or by running `superclose` if you installed the shell command into a directory on your `PATH`. The first run will prompt for Accessibility permission, which is required to inspect window state across other apps.

When the review window opens, each row shows an app with its open and hidden window counts and a default action chosen by SuperClose's heuristics. Adjust any rows you want, then press `Enter` (or click `Run`) to apply every selection at once. `Esc` cancels without touching anything.

### Actions

- `Ignore` — leave the app alone
- `Hide` — hide the app's windows (AppKit hide)
- `Quit` — graceful quit
- `Kill` — force-quit (use when an app is wedged)

### Keyboard Shortcuts

- `↑` / `↓` — move between rows
- `←` / `→` — cycle the action for the selected row
- `A` / `S` / `D` / `F` — set the selected row to Ignore / Hide / Quit / Kill
- `Enter` — run the selected actions
- `Esc` — cancel and quit

### CLI

The installed `superclose` command is backed by the [scripts/superclose](/Users/kevin/code/superclose/scripts/superclose) wrapper, which launches the installed app bundle and forwards arguments. `--help` prints usage and `--dump` prints the candidate app list without showing the UI, which is handy for scripting or debugging the heuristics.

# Contributing Guide

## Project Layout

- `SuperClose/`: app source and resources
- `SuperCloseTests/`: unit tests for rules and CLI output
- `scripts/`: archive, notarization, packaging, and cask helpers
- `packaging/homebrew/`: maintained cask file
- `docs/`: release and publishing instructions

## Local Run

SuperClose is a native Swift/AppKit app targeting macOS 14+ and built with Swift 6. The Xcode project is generated from [scripts/generate-project.rb](/Users/kevin/code/superclose/scripts/generate-project.rb) (requires the `xcodeproj` Ruby gem) — regenerate it whenever you add or remove source files:

```sh
ruby scripts/generate-project.rb
```

Then open `SuperClose.xcodeproj` in Xcode and run the `SuperClose` scheme, or build from the command line:

```sh
xcodebuild -project SuperClose.xcodeproj -scheme SuperClose \
  -configuration Debug -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO build
```

Run the unit tests with:

```sh
xcodebuild -project SuperClose.xcodeproj -scheme SuperClose \
  -configuration Debug -destination "platform=macOS" test
```

Signing settings for release builds live in `Config/Signing.local.xcconfig` (copy `Signing.local.xcconfig.example` to get started). Release archiving, notarization, packaging, and Homebrew cask generation are handled by the helper scripts in `scripts/`.
