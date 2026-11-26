cask "dinkycal" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE_SCRIPT"

  url "https://github.com/joshtronic/dinkycal/releases/download/v#{version}/DinkyCal-#{version}.zip"
  name "Dinky Cal"
  desc "Tiny menu bar month calendar with a busy-day heatmap"
  homepage "https://dinkycal.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "DinkyCal.app"

  uninstall quit: "com.joshtronic.dinkycal"

  zap trash: [
    "~/Library/Containers/com.joshtronic.dinkycal",
    "~/Library/Application Scripts/com.joshtronic.dinkycal",
  ]
end
