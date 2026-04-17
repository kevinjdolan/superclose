# Homebrew Publishing

This repo packages SuperClose as a Homebrew Cask.

## Why a cask

SuperClose is a GUI macOS app. The release artifact is a signed and notarized `SuperClose.app` zip, so Homebrew Cask is the right distribution shape.

## Files

- Cask template: [packaging/homebrew/superclose.rb](/Users/kevin/code/superclose/packaging/homebrew/superclose.rb)
- Generator: [scripts/generate-cask.sh](/Users/kevin/code/superclose/scripts/generate-cask.sh)
- Submission guide: [docs/brew-cask-submission.md](/Users/kevin/code/superclose/docs/brew-cask-submission.md)

## Typical flow

1. Publish a GitHub Release with `SuperClose-<version>.zip`.
2. Compute the SHA-256:
   ```sh
   shasum -a 256 dist/SuperClose-0.1.0.zip
   ```
3. Generate the cask file:
   ```sh
   ./scripts/generate-cask.sh \
     --version 0.1.0 \
     --sha256 <sha256> \
     --repo kevinjdolan/superclose
   ```
4. Validate locally:
   ```sh
   brew install --cask ./packaging/homebrew/superclose.rb
   brew uninstall --cask superclose
   brew audit --new --cask ./packaging/homebrew/superclose.rb
   ```
5. Submit it upstream or publish it from your own tap.

