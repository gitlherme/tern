# AGENTS.md

Guidance for AI coding agents working on Tern.

## Project

Tern is a native macOS window switcher (Swift, SwiftUI + AppKit) that lives in the menu bar (`LSUIElement`, no Dock icon). ⌥⇥ opens a HUD of open windows ordered by recency; ⌫ hides an app from the switcher, ⌥⌫ hides a single window.

- Bundle id: `dev.guilhermevieira.Tern`
- Deployment target: macOS 13.0, universal (arm64 + x86_64)
- No sandbox and a private API (`_AXUIElementGetWindow`), so it can't ship on the Mac App Store. Distribution is a `.dmg` on GitHub Releases.

```
Tern.xcodeproj           Xcode project (file references are explicit: new files must be added to project.pbxproj)
Tern/                    app sources, Localizable.xcstrings, InfoPlist.xcstrings
brand/                   icon, wordmark, demo animation script
site/                    static landing page: pt-BR at /, English at /en/
```

## Build

```bash
xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Debug -destination 'platform=macOS' build
```

Release build used for published `.dmg` files (ad-hoc signed until there is a Developer ID):

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

- Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj` and tag `vX.Y.Z`.
- Attach `Tern-X.Y.Z.dmg` (the `.app` plus an `/Applications` symlink).
- Release notes are bilingual (Portuguese first, then English) and include the step-by-step install guide written for non-technical users, including how to allow the first launch of a non-notarized app.
- The site's download buttons point to `releases/latest`, so they don't need updating per release.
