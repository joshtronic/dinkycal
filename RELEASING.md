# Releasing Dinky Cal

Dinky Cal ships two ways from the same code:

- **Mac App Store**, $0.99, uploaded from Xcode's Organizer.
- **GitHub Releases + Homebrew**, free, a universal app signed with Developer ID and notarized.

## One-time setup

1. **Xcode project.** It's generated from `project.yml` and committed. After editing
   `project.yml`, run `xcodegen generate` (`brew install xcodegen`).
2. **Certificates.** Apple Distribution (App Store) and Developer ID Application (GitHub) for team
   S4F666RB9G, both in the login keychain.
3. **Notarization credentials.** Any `notarytool` keychain profile for the team works. The release
   script defaults to the existing `hautekey` profile. To make a dedicated one:

   ```sh
   xcrun notarytool store-credentials dinkycal \
       --apple-id <your Apple ID email> --team-id S4F666RB9G --password <app-specific password>
   export NOTARY_PROFILE=dinkycal
   ```

4. **App Store Connect record** (once): bundle ID `com.joshtronic.dinkycal`, name
   "Dinky Cal: Menu Bar Calendar", SKU `dinkycal`.
5. **Homebrew tap:** `joshtronic/homebrew-tap` holds `Casks/dinkycal.rb`, copied from
   `packaging/dinkycal.rb`.

## GitHub + Homebrew release

From a clean `main`:

```sh
scripts/release.sh 1.0.0
```

The script checks the tree (clean, on `main`, matching `origin/main`), archives a universal Release build (version `1.0.0`, build number =
commit count), exports it with Developer ID, notarizes, staples, checks it with Gatekeeper, zips it to
`build/DinkyCal-1.0.0.zip`, prints the SHA-256, and creates a **draft** GitHub
Release targeting that commit. GitHub creates the `v1.0.0` tag when you publish the draft.

Then:

1. Review the draft on GitHub, edit the notes, and publish it. Then `git fetch --tags`.
2. In the tap repo, set `version` and `sha256` in `Casks/dinkycal.rb`. Commit and push.
3. Check it: `brew install --cask joshtronic/tap/dinkycal`.

`scripts/release.sh 1.0.0 --dry-run` runs the archive and zip with your development signature and
skips the export, notarization, tag, and release.

## App Store release

1. In `project.yml`, bump `MARKETING_VERSION` if needed and set `CURRENT_PROJECT_VERSION` to
   `git rev-list --count HEAD` (App Store Connect rejects a build number it has seen before), then
   run `xcodegen generate`.
2. Open `DinkyCal.xcodeproj`, choose **Product → Archive**.
3. In the Organizer, **Distribute App → App Store Connect → Upload**.
4. In App Store Connect, attach the build to the version, fill in what's new, and submit.

Listing details: support URL `https://dinkycal.com/support`, privacy policy URL
`https://dinkycal.com/privacy`, category Productivity, price $0.99. Privacy "nutrition label":
**Data Not Collected**.

## Website

`site/` deploys to GitHub Pages through `.github/workflows/pages.yml` on every push to `main` that
touches it. With Actions deploys, `site/CNAME` is not enough: set the custom domain once in the repo's
Settings → Pages (`dinkycal.com`) and turn on Enforce HTTPS.

## App icon

The icon is drawn in code by `art/make-icon.swift`. After changing it, run `scripts/make-icon.sh`
to regenerate the asset catalog sizes.
