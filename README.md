# Dinky Cal

A tiny month calendar for your macOS menu bar.

Click the date in your menu bar and get the month. Days with events get a dot, brighter the
busier the day is. Hover a day to see how far away it is ("In 7 days"), click it to see what's on.
It reads the calendars already on your Mac (iCloud, Google, Exchange, anything in Internet
Accounts) and never sends anything anywhere.

**[dinkycal.com](https://dinkycal.com/)**

## Install

- **Mac App Store**: free, with dinky support tiers inside.
- **Homebrew**: `brew install --cask joshtronic/tap/dinkycal`
- **GitHub**: download the latest zip from
  [Releases](https://github.com/joshtronic/dinkycal/releases).

Requires macOS 14 Sonoma or later.

Everything is free. If you'd like to support it, tip in the App Store version or
[sponsor on GitHub](https://github.com/sponsors/joshtronic).

## Build from source

```sh
brew install xcodegen
xcodegen generate
open DinkyCal.xcodeproj
```

The date and busy-day logic lives in `Packages/DinkyCalCore` and is tested with
`swift test --package-path Packages/DinkyCalCore`.

## License

Dinky Cal is free software, licensed under the
[GNU General Public License v3.0 or later](LICENSE).

This project doesn't accept outside contributions. Bug reports are welcome at
hello@dinkycal.com.
