# Blockers

Each entry: what is blocked, why, the workaround tried, and what remains.

## B1. V-Sync warning under WSLg (environmental, not fixable)
- **What:** Every windowed Godot launch prints `WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.`
- **Why:** The WSLg Mesa (llvmpipe) GL driver does not expose swap-interval control.
- **Workaround tried:** none possible from the project side; setting `display/window/vsync/vsync_mode` does not change the driver capability.
- **Status:** exempt from the zero-warnings check by agreement with the project owner. All other warnings are held at zero.
