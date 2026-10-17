# Building and Installing physio-nudge

This guide shows you how to turn the source code in this repository into a
runnable app on your Mac, in two ways: with **Xcode** (GUI) or with the
**Terminal** (script). Both produce the same result: `PhysioNudge.app`.

## Prerequisites

- A Mac with **macOS 13 (Ventura)** or later
- **Xcode 14 or later** — includes the Swift compiler and everything else
  needed. After installing Xcode once, no further setup is required:

  ```bash
  xcode-select --install  # only if Xcode command line tools are missing
  ```

  Verify the toolchain works:

  ```bash
  swift --version
  ```

## Option 1 — Terminal (recommended, one command)

```bash
git clone https://github.com/yauh-mistral/physio-nudge.git
cd physio-nudge
bash Scripts/make-app.sh
```

The script:

1. builds the app in Release configuration (Swift Package Manager),
2. bundles the binary plus resources into `.build/PhysioNudge.app`,
   including an `Info.plist` with `LSUIElement = true` (no Dock icon),
3. **launches the app immediately.**

You will find the app at `.build/PhysioNudge.app` inside the repository.
Look for the physio-nudge icon in your **menu bar** — the app deliberately
has no Dock icon.

## Option 2 — Xcode (GUI)

1. Clone the repository and open the folder in Xcode
   (`File > Open…`, select the `physio-nudge` folder; Xcode detects the
   `Package.swift`).
2. Select the **PhysioNudge** scheme and set the build configuration to
   **Release** (`Product > Scheme > Edit Scheme… > Run > Build
   Configuration > Release`).
3. Run it with **⌘R** — the app starts and the menu-bar icon appears.

Note: running from Xcode starts the binary directly, without an `.app`
bundle. To get a proper `.app` bundle out of an Xcode session, build once
(⌘B), then run `bash Scripts/make-app.sh` to bundle the Release binary —
the script reuses the SwiftPM build output.

## "Installing" it locally

macOS apps don't need an installer. To make the app a permanent part of
your system:

1. Build it (Option 1 above).
2. Move the bundle anywhere convenient, e.g.:

   ```bash
   mv .build/PhysioNudge.app /Applications/
   open /Applications/PhysioNudge.app
   ```

   In Finder: drag `PhysioNudge.app` from the `.build` folder into
   `Applications`, then double-click it.

3. Optional — start automatically at login:
   `System Settings > General > Login Items > +` and add
   `PhysioNudge.app`.

### First launch warning (Gatekeeper)

The app is **unsigned**. On first launch, macOS may show
"`PhysioNudge` can't be opened because it is from an unidentified
developer." That is expected for a locally built, unsigned app. Two ways
to proceed:

- **Right-click → Open** in Finder, then confirm **Open** in the dialog, or
- `System Settings > Privacy & Security`, scroll down and click
  **Open Anyway**.

If macOS refuses the app entirely (rare on newer macOS versions), open it
once via Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/PhysioNudge.app
```

(For apps you built yourself this quarantine attribute is usually absent —
it mostly applies to downloaded files.)

## Verifying it runs

- No Dock icon appears.
- A physio-nudge icon appears in the menu bar; clicking it opens the menu.
- With the default exercise catalog, the overlay appears in a configurable
  corner after the configured interval; use the menu to trigger it
  immediately ("Exercise now" / current equivalent) to test without
  waiting.

## Updating to a new version

```bash
cd physio-nudge
git pull
bash Scripts/make-app.sh
```

Then replace the old app bundle with `.build/PhysioNudge.app` (or run it
directly from the build folder).

## Uninstalling

Drag `PhysioNudge.app` to the Trash. The app stores its data in exactly
one folder:

```bash
~/Library/Application Support/PhysioNudge/
```

Delete that folder too and no traces remain (this is a requirements-level
guarantee, see `requirements/07-non-functional-requirements.md`, NFR-16).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `swift: command not found` | install Xcode or run `xcode-select --install` |
| Build succeeds, but no menu-bar icon | the app is running but the icon may be hidden — check `Activity Monitor` for `PhysioNudge`; menu-bar overflow tools can hide it |
| App won't start (unidentified developer) | see Gatekeeper section above |
| `bash Scripts/make-app.sh` fails at `swift build` | run `swift build` alone to see the full compiler error; ensure macOS ≥ 13 |

## Future: prebuilt binaries

Releases will later ship prebuilt, signed, notarized binaries, so none of
the build steps above will be necessary — watch the repository's
Releases page.
