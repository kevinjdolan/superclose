# Why the full app is not targeting the Mac App Store

SuperClose depends on macOS Accessibility APIs to inspect other apps' windows and then hide, quit, or force-quit those apps in bulk.

That makes it a poor fit for a full Mac App Store release:

- the Mac App Store expects sandboxed apps
- the full product needs system-level visibility into and control over other apps
- reducing the app enough to fit sandbox restrictions would create a separate product with different behavior

For that reason this repository targets:

- direct distribution of a signed, notarized `SuperClose.app`
- GitHub Releases for downloads
- Homebrew Cask for install automation

If you decide later to ship an App Store edition, plan it as a separate reduced app instead of trying to squeeze the full Accessibility-based workflow into the same binary.

