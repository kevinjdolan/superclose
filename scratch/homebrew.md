# Homebrew Publishing

This repo packages SuperClose as a Homebrew Cask.

## Why a cask

SuperClose is a GUI macOS app. The release artifact is a signed and notarized `SuperClose.app` zip, so Homebrew Cask is the right distribution shape.

## Files

- Cask template: [packaging/homebrew/superclose.rb](/Users/kevin/code/superclose/packaging/homebrew/superclose.rb)
- Generator: [scripts/generate-cask.sh](/Users/kevin/code/superclose/scripts/generate-cask.sh)

## Official `homebrew/cask` flow

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
     --repo kevin/superclose
   ```
4. Validate locally:
   ```sh
   brew install --cask ./packaging/homebrew/superclose.rb
   brew uninstall --cask superclose
   brew audit --new --cask ./packaging/homebrew/superclose.rb
   ```
5. Fork `Homebrew/homebrew-cask`.
6. Copy the generated cask into `Casks/s/superclose.rb` in your fork.
7. Open a PR and watch for reviewer feedback.

## If the official cask is rejected

If `homebrew/cask` rejects the PR because the project is too new or does not meet public-presence thresholds yet:

1. Create your own tap, for example `kevin/homebrew-superclose`.
2. Add the same `superclose.rb` cask there.
3. Publish install instructions like:
   ```sh
   brew tap kevin/superclose
   brew install --cask superclose
   ```

The packaging in this repo stays the same either way.

