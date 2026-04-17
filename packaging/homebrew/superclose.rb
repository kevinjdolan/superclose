cask "superclose" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/kevinjdolan/superclose/releases/download/v#{version}/SuperClose-#{version}.zip",
      verified: "github.com/kevinjdolan/superclose/"
  name "SuperClose"
  desc "Bulk hide, quit, and force-quit helper for macOS"
  homepage "https://github.com/kevinjdolan/superclose"

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
