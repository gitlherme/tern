<p align="center">
  <img src="brand/tern-icon.svg" width="128" height="128" alt="Tern icon">
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brand/tern-wordmark-light.svg">
    <img src="brand/tern-wordmark-dark.svg" height="56" alt="Tern">
  </picture>
</p>

<p align="center">
  <strong>Free, open-source Alt-Tab for Mac: a window switcher that lets you hide the apps you don't need.</strong><br>
  <kbd>⌥</kbd> <kbd>⇥</kbd> to switch windows · type to search · <kbd>⌫</kbd> to hide an app
</p>

<p align="center">
  <strong>English</strong> · <a href="README.pt-BR.md">Português</a>
</p>

---

Tern is a free, native macOS window switcher (an Alt-Tab for Mac) that lives in the menu bar, with no Dock icon. A global shortcut opens a HUD to cycle through and focus open windows — in the spirit of [alt-tab.app](https://alt-tab.app), with one twist: you can **hide an app (or a single window)** and it stays out of the switcher until you take it off the list.

Type-to-search is included, not a paid add-on. Example: five apps open, one on the exclusion list, and the shortcut shows only the other four.

## Tern vs AltTab

Both are open-source window switchers for Mac. [AltTab](https://alt-tab.app) is the established one: notarized, Space badges, full-size previews. Its type-to-search is a Pro feature. Tern ships search for free and is built around hiding apps, windows, title rules, snooze, and Focus modes. Tern is not notarized yet, so the first launch needs **Open Anyway**. A longer comparison is on the [site](https://tern.gitlher.me/en/alttab-alternatives/).

## FAQ

**Does the Mac have Alt-Tab?** No. ⌘⇥ switches apps, not windows. Tern uses ⌥⇥ to switch window by window.

**Why Accessibility?** macOS only lets an app read window titles and bring a window forward with Accessibility on. Tern does not read window contents.

**Why the first-launch warning?** The app is signed with its own certificate, not Apple notarization. Grant **Open Anyway** once; later updates do not ask again. Step-by-step: [Help](https://tern.gitlher.me/en/help/).

## Download

Get **`Tern-x.y.z.dmg`** from the [latest release](https://github.com/gitlherme/tern/releases/latest), open it, and drag Tern into **Applications**.

The app isn't notarized by Apple yet, so macOS blocks the first launch. Open Tern once, dismiss the warning, then go to **System Settings › Privacy & Security › Open Anyway**. Or run:

```bash
xattr -dr com.apple.quarantine /Applications/Tern.app
```

Then grant Accessibility when Tern asks and press **⌥⇥**.

## Features

- Menu bar app (`LSUIElement`), Swift + SwiftUI/AppKit.
- Configurable global shortcut (default **⌥⇥**). The HUD floats over the frontmost app, and the shortcut **doesn't** also fire in your browser. Hold the modifier and tap the key again to move forward; release the modifier to focus the window. **⇧⇥** moves back. Click, **⏎**, and **esc** work too.
- **Type to search:** with the switcher open, type to filter windows by app name and title ("vsc" finds Visual Studio Code).
- **Window actions:** **⌘W** closes the highlighted window, **⌘M** minimizes it, **⌘Q** quits its app.
- Exclusion by **bundle id** (the main path), by window (bundle id + title), and by **title rule** (text or `*` pattern, in one app or any app).
- **Snooze:** **⇧⌫** hides an app for an hour; in Settings, hide for 1 hour, until tomorrow, or always.
- **Modes:** named sets of extra apps to hide (Work, Personal…), switched from the menu bar or automatically by a **macOS Focus** through a Focus Filter.
- **Automation:** Shortcuts actions and a `tern://` URL scheme (see below).
- Live preview of each window on its card (with Screen Recording permission).
- UI in **English and Portuguese** (follows the macOS language; other languages fall back to English).
- Exclusions and shortcut persisted in `UserDefaults`.
- Settings to record the shortcut, grant Accessibility, and add or remove exclusions.

In the switcher: **⌫** hides the highlighted window's app, **⇧⌫** hides it for an hour, **⌥⌫** hides just that window. While searching, **⌫** edits the search instead.

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build from source)
- A free Apple ID to sign the app locally

## Build and run

```bash
git clone https://github.com/gitlherme/tern.git
cd tern
open Tern.xcodeproj
```

In Xcode:

1. Pick the **Tern** scheme.
2. Under **TARGETS › Tern › Signing & Capabilities**, check *Automatically manage signing* and choose your **Personal Team**. With a stable signature, Accessibility and Screen Recording permissions survive rebuilds.
3. Run (**⌘R**). Tern shows up in the menu bar, not the Dock.

From the command line:

```bash
xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Debug -destination 'platform=macOS' build
```

### Install for daily use

**Product › Archive › Distribute App › Custom › Copy App**, then move `Tern.app` into `/Applications`. Add it under System Settings › General › Login Items.

## Permissions

### Accessibility (required)

macOS only lets Tern **read window titles** and **bring the chosen window to the front** with Accessibility on.

1. Run Tern.
2. Press **⌥⇥** (or your recorded shortcut). If the permission is off, the HUD asks for Accessibility.
3. Click **Open System Settings** (or **Request permission** for the native prompt).
4. System Settings → Privacy & Security → **Accessibility**.
5. Turn on **Tern**. If it isn't listed, click **+** and choose `Tern.app` from DerivedData or Xcode's Products folder.
6. Go back to Tern and use the shortcut again.

If you rebuild with a different path or signature, macOS treats it as a new app: toggle Tern off and on in the list, or remove it and add it again.

Direct links (Ventura/Sonoma/Sequoia):

- `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
- `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility`

### Input Monitoring (only if the shortcut leaks)

With Accessibility on, Tern installs an event tap and **swallows** the shortcut so ⌥⇥ doesn't also run in your browser. On most macOS versions that's enough.

If the frontmost app still reacts to the shortcut, turn on **Input Monitoring** for Tern:

System Settings → Privacy & Security → **Input Monitoring**.

- `x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent`

### Screen Recording (previews)

Cards show a **thumbnail of each window**, which macOS gates behind Screen Recording. Without it the switcher **still switches windows**; only the preview goes away.

1. In Tern Settings, click **Request permission** (or **Show Tern.app in Finder**). This selects Tern in Finder. When run from Xcode, it first copies the app to `~/Applications/Tern.app`, since the Settings + button can't reach DerivedData.
2. System Settings → Privacy & Security → **Screen & System Audio Recording**.
3. Tern **doesn't add itself** to this list. Click **+**, choose `Tern.app` (the one selected in Finder) or drag it into the list, and turn the switch on.
4. Menu bar → **Quit**, then run Tern again. The new permission only applies to the next process.

With "Sign to Run Locally" (`adhoc` signature), every rebuild changes the `cdhash` and the switch may need to be turned on again. Signing with your Personal Team avoids that.

- `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`
- `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture`

## Usage

1. Grant Accessibility. For previews, grant Screen Recording too.
2. **⌥⇥** opens the switcher with the current window at index 0 and the previous one at 1. Release ⌥ to jump to the previous window; ⇥ moves further back in recency. Minimized windows come last and are restored when focused.
3. Keep going with ⇥ / arrow keys, release ⌥ to focus, or click a card.
4. Start typing to search. Once you type, releasing ⌥ no longer confirms: **⏎** opens, **esc** clears the search.
5. To hide an app: Settings → Exclusions → **Add running app…**, or **⌫** in the switcher (**⇧⌫** for an hour).
6. To hide a single window: **Add open window…** or **⌥⌫**. To hide windows whose title changes, add a **title rule**.
7. Modes: Settings → Modes. To link one to a Focus, go to System Settings › Focus › (a Focus) › Focus Filters › Add Filter › Tern.
8. Menu bar: Open switcher, Mode, Settings, Check for Updates, Quit.

### Automation

Shortcuts app actions: **Open Tern switcher**, **Hide app in Tern** (always, 1 hour, until tomorrow), **Show app in Tern**, and **Set Tern mode**.

URL scheme, for scripts, Raycast, or anything that opens links:

| URL | Does |
|---|---|
| `tern://open` | Opens the switcher |
| `tern://hide?app=com.spotify.client` | Hides an app (add `&for=1h` or `&for=tomorrow` to snooze) |
| `tern://unhide?app=com.spotify.client` | Shows it again |
| `tern://mode?name=Work` | Turns on a mode; `tern://mode` turns it off |

Any web page can open a `tern://` link, so URLs only do harmless things: nothing closes windows or quits apps.

Don't record **⌘⇥**: macOS reserves it for the app switcher.

## Known limitations

- Order is by recency: current window → previous → other recently used → minimized last.
- Window exclusions match the exact title: if it changes, the window shows up again. Title rules cover that case.
- Doesn't replace the system's ⌘⇥.
- No sandbox: utilities like this need to talk to other apps' windows, which also rules out the Mac App Store.

## Project structure

```
Tern.xcodeproj           Xcode project
Tern/
  TernApp.swift          SwiftUI entry point, no Dock icon
  AppModel.swift         state, shortcut, exclusions
  Localizable.xcstrings  UI strings (pt-BR source → en)
  Models/                window, exclusion, shortcut
  Services/              AX windows, CG metadata, previews, Carbon hotkey, persistence
  Views/                 HUD, settings, menu bar
brand/                   icon, wordmark, and variants
site/                    landing page (static HTML, pt-BR and en/)
```

Bundle id: `dev.guilhermevieira.Tern`. Deployment target: macOS 13+.

## Supporters

Thanks to everyone who supports Tern on Ko-fi. Supporters who opt in are listed here.

[https://ko-fi.com/gitlherme](https://ko-fi.com/gitlherme)

<!-- Names are only added with the supporter's explicit permission. -->

## License

[MIT](LICENSE) © Guilherme Vieira. Free and open source: use, modify, and redistribute it as you like.
