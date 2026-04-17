# Release Checklist

This checklist is for the direct-distribution release of `SuperClose.app`.

## 1. Prepare the machine

1. Install full Xcode in `/Applications/Xcode.app`.
2. Point command line tooling at full Xcode:
   ```sh
   sudo xcode-select -s /Applications/Xcode.app
   ```
3. Confirm the tools are available:
   ```sh
   xcodebuild -version
   xcrun notarytool --help >/dev/null
   ```

## 2. Prepare Apple developer access

1. Join the Apple Developer Program if this Apple ID is not already enrolled.
2. Create or import a `Developer ID Application` certificate into your login keychain.
3. Create a notary credential profile:
   ```sh
   xcrun notarytool store-credentials SuperCloseNotary \
     --apple-id "you@example.com" \
     --team-id "YOURTEAMID" \
     --password "app-specific-password"
   ```
4. Copy [Config/Signing.local.xcconfig.example](/Users/kevin/code/superclose/Config/Signing.local.xcconfig.example) to `Config/Signing.local.xcconfig` and fill in the real values.

## 3. Choose the release version

1. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in [Config/Project.xcconfig](/Users/kevin/code/superclose/Config/Project.xcconfig).
2. Update [CHANGELOG.md](/Users/kevin/code/superclose/CHANGELOG.md).
3. Commit the release changes and tag them after validation.

## 4. Archive and export

1. Archive the app:
   ```sh
   ./scripts/archive-release.sh
   ```
2. Export the signed Developer ID build:
   ```sh
   ./scripts/package-release.sh --skip-notarization
   ```

Artifacts are written under `dist/`.

## 5. Notarize and staple

1. Submit the exported app bundle zip for notarization and wait for completion:
   ```sh
   ./scripts/notarize-release.sh
   ```
2. Re-run packaging without `--skip-notarization` if you want a fresh stapled archive in one pass:
   ```sh
   ./scripts/package-release.sh
   ```

## 6. Verify the packaged build

1. Check Gatekeeper assessment:
   ```sh
   spctl --assess --type exec --verbose dist/SuperClose.app
   ```
2. Open the packaged app on a clean macOS user account if possible.
3. Verify:
   - first launch prompts for Accessibility when needed
   - the window list renders correctly
   - `Hide`, `Quit`, and `Kill` still work
   - `SuperClose.app/Contents/MacOS/SuperClose --dump` still prints candidate output

## 7. Publish the release

1. Create a Git tag:
   ```sh
   git tag v0.1.0
   ```
2. Create a GitHub Release for the matching tag.
3. Upload:
   - `dist/SuperClose-0.1.0.zip`
   - `dist/SuperClose-0.1.0.sha256`
   - optional release notes copied from [CHANGELOG.md](/Users/kevin/code/superclose/CHANGELOG.md)

## 8. Update Homebrew

1. Generate the cask with the final version, GitHub repo slug, and SHA:
   ```sh
   ./scripts/generate-cask.sh \
     --version 0.1.0 \
     --sha256 "$(cut -d' ' -f1 dist/SuperClose-0.1.0.sha256)" \
     --repo kevinjdolan/superclose
   ```
2. Follow [docs/brew-cask-submission.md](/Users/kevin/code/superclose/docs/brew-cask-submission.md) to validate and submit it.

