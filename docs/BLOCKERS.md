# Blockers

Each entry: what is blocked, why, the workaround tried, and what remains.

## B1. V-Sync warning under WSLg (environmental, not fixable)
- **What:** Every windowed Godot launch prints `WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.`
- **Why:** The WSLg Mesa (llvmpipe) GL driver does not expose swap-interval control.
- **Workaround tried:** none possible from the project side; setting `display/window/vsync/vsync_mode` does not change the driver capability.
- **Status:** exempt from the zero-warnings check by agreement with the project owner. All other warnings are held at zero.

## B2. Android and iOS packages can't be built on this machine
- **What:** `--export-release "Android"` and `--export-release "iOS"` stop at Godot's configuration check.
- **Why:** Android needs a Java SDK and the Android SDK (platform-tools, build-tools) configured in Editor Settings; iOS needs an Apple developer Team ID and, to build the IPA, macOS with Xcode. None of these exist in this WSL environment, and the brief does not require signed mobile builds.
- **Workaround tried:** installed the official Godot 4.7.2 export templates (all platforms) and exported every preset. Linux, Windows and Web export successfully; the exported Linux build boots with zero errors and `-- --selftest` confirms it ships all 12 puzzles, 3 chapters, 18 Codex entries, 28 dialogues and the n-gram tables. The Android and iOS presets load and validate up to the SDK/Team ID checks, which report exactly the missing machine-level items.
- **Status:** presets are present and complete (package names, versions, orientation, vibrate permission, arm64). To build: set Java and Android SDK paths in Editor Settings (and a debug keystore), or an Apple Team ID on a Mac.
