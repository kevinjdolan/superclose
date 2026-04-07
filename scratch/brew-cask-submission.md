# Sending SuperClose to Homebrew Cask

This is the maintainer checklist for submitting SuperClose to the upstream `Homebrew/homebrew-cask` repository.

## 1. Ship the direct-download release first

Before you open a Homebrew PR, make sure you already have:

- a signed and notarized `SuperClose.app`
- a published GitHub Release
- an uploaded `SuperClose-<version>.zip` artifact
- the final SHA-256 for that zip

Use [docs/release.md](/Users/kevin/code/superclose/docs/release.md) to produce those release assets first.

## 2. Generate the cask file

Run:

```sh
./scripts/generate-cask.sh \
  --version 0.1.0 \
  --sha256 <release-zip-sha256> \
  --repo kevin/superclose
```

That rewrites [packaging/homebrew/superclose.rb](/Users/kevin/code/superclose/packaging/homebrew/superclose.rb) with the current release values.

## 3. Validate locally

Run all three:

```sh
brew install --cask ./packaging/homebrew/superclose.rb
brew uninstall --cask superclose
brew audit --new --cask ./packaging/homebrew/superclose.rb
```

If the cask installs the app correctly and `brew audit` passes, you are ready to submit it.

## 4. Open the upstream PR

1. Fork `Homebrew/homebrew-cask`.
2. Clone your fork locally.
3. Copy the generated cask into `Casks/s/superclose.rb`.
4. Commit the new cask.
5. Push your branch.
6. Open a PR to `Homebrew/homebrew-cask`.

## 5. What to say in the PR

Keep it short and concrete:

- explain that SuperClose is a signed, notarized macOS utility app
- link to the GitHub release asset used in the cask
- mention that you validated install, uninstall, and `brew audit`

## 6. If reviewers push back

If the upstream submission is rejected because the project is too new or lacks enough public presence yet:

1. Create your own tap, such as `kevin/homebrew-superclose`.
2. Commit the same cask there.
3. Publish install instructions from that tap until the project is established enough to retry upstream.

The cask file in this repo is designed to work in either location.

