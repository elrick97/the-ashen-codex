# Environment (recon, 2026-09-27)

| Item | Finding |
|---|---|
| Host | Windows 11, WSL2 Ubuntu 26.04 LTS, kernel 6.6.114.1-microsoft-standard-WSL2 |
| CPU / RAM | 16 logical CPUs, ~7 GB RAM visible to WSL |
| Godot | Not on PATH. Downloaded **Godot 4.7.2-stable** (`Godot_v4.7.2-stable_linux.x86_64.zip`, found via the GitHub releases API) into `./.tools/godot/`. Use it through `./tools_dev/godot.sh`. `$GODOT` = `./tools_dev/godot.sh`. Reports `4.7.2.stable.official.ed1daf0bf`. |
| Display | WSLg: `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-0`. `xvfb-run` also installed at `/usr/bin/xvfb-run`. Rendered screenshots work (Mesa llvmpipe, OpenGL 3 / Compatibility renderer). |
| Audio | PulseAudio via WSLg (`libpulse0`, `libasound2t64` installed). |
| Python | Python 3.14.4 (`/usr/bin/python3`) |
| Git | 2.53.0 |
| Network | `api.github.com` and `fonts.google.com` reachable (HTTP 200). |
| Test framework | GUT 9.7.1 vendored into `addons/gut` (MIT, license in `licenses/GUT_LICENSE.md`). |

## Known environmental warnings
- `Could not set V-Sync mode` is printed by the WSLg/llvmpipe driver at every windowed launch. It is a driver limitation, not a project defect, and is exempt from the zero-warnings check (see BLOCKERS.md).

## How the lead agent ran commands
The Claude Code session ran on the Windows side and executed every command in WSL via `wsl.exe -d Ubuntu --cd ~/dev/ashen-codex --exec bash -lc '<cmd>'`. Files were edited through `\\wsl.localhost\Ubuntu\home\ricardo\dev\ashen-codex`.
