# AGENTS.md

Guidance for AI coding agents working on Tern.

## Project

Tern is a native macOS window switcher (Swift, SwiftUI + AppKit) that lives in the menu bar (`LSUIElement`, no Dock icon). ⌥⇥ opens a HUD of open windows ordered by recency; ⌫ hides an app from the switcher, ⌥⌫ hides a single window.

- Bundle id: `dev.guilhermevieira.Tern`
- Deployment target: macOS 13.0, universal (arm64 + x86_64)
- No sandbox and a private API (`_AXUIElementGetWindow`), so it can't ship on the Mac App Store. Distribution is a `.dmg` on GitHub Releases.
- Releases are signed with a self-signed certificate, **"Tern Code Signing"**, in the owner's Keychain (valid until 2036). The app's designated requirement is `identifier "dev.guilhermevieira.Tern" and certificate root = H"0d03d761…"`, so macOS keeps the Accessibility permission across updates. Never ship an ad-hoc build: every user would have to re-grant Accessibility. Losing this certificate has the same effect once.

```
Tern.xcodeproj           Xcode project (file references are explicit: new files must be added to project.pbxproj)
Tern/                    app sources, Localizable.xcstrings, InfoPlist.xcstrings
brand/                   icon, wordmark, demo animation script
scripts/                 release.sh and per-version release notes for Sparkle
site/                    static landing page: pt-BR at /, English at /en/
```

## Build

```bash
xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Debug -destination 'platform=macOS' build
```

Release build (`scripts/release.sh` runs it ad-hoc, then re-signs inside-out with the "Tern Code Signing" certificate):

```bash
xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Release -destination 'generic/platform=macOS' ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" build
```

## Localization

- UI ships in Portuguese (source language, `pt-BR`) and English. `CFBundleDevelopmentRegion` is `en`, so other system languages fall back to English.
- Every user-facing string must be translated in `Tern/Localizable.xcstrings`. SwiftUI `Text`/`Button`/`Label` literals localize automatically; AppKit strings, alerts and functions returning `String` must use `String(localized:)`.
- After changing strings, build and confirm every key in the compiler's `.stringsdata` output exists in the catalog, with no stale entries left behind.
- User-facing copy must make sense for someone who installed the `.dmg`, not only for someone running from Xcode.

## Commits and pull requests

- **Never add `Co-Authored-By` trailers** (Claude, Cursor, or any other agent) to commit messages.
- Commits are authored as `Guilherme Vieira <code@gitlher.me>`. Check `git config user.email` before committing.
- Commit messages are in Portuguese: a short imperative-style subject ending with a period (for example, "Adiciona a licença MIT."), and an optional body explaining why.
- Don't rewrite published history or force-push without the owner asking for it.

## Releases

`scripts/release.sh` builds the universal `.app`, re-signs it with the "Tern Code Signing" certificate (and refuses to continue without it), opens it for a few seconds to catch launch crashes, packages `Tern-X.Y.Z.dmg` (the `.app` plus an `/Applications` symlink), and updates `site/appcast.xml` for Sparkle, signing with the EdDSA key stored in the owner's Keychain under the account `tern`. The private key never goes into the repo; losing it means existing installs can no longer verify updates.

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (the build number must always increase; Sparkle compares it).
2. Optionally add `scripts/release-notes/X.Y.Z.html`; it gets embedded in the update dialog.
3. Run `scripts/release.sh`.
4. Publish the GitHub release `vX.Y.Z` with that exact `.dmg` **before** pushing the new `site/appcast.xml` to `main`; the app reads the appcast from `raw.githubusercontent.com/gitlherme/tern/main/site/appcast.xml`.
5. Release notes are bilingual (Portuguese first, then English) and include the step-by-step install guide written for non-technical users, including how to allow the first launch of a non-notarized app Updates from 1.1.3 on keep Accessibility; only a change of signing certificate (for example, moving to a Developer ID) makes users grant it again once.

The site's download buttons point to `releases/latest`, so they don't need updating per release.
