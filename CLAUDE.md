# CLAUDE.md

## Project

My Claw — native macOS SwiftUI app for monitoring and managing Claude Code scheduled jobs and sessions. Built with SwiftPM (not Xcode), targets macOS 14+, zero external dependencies.

## Build & Run

```bash
cd MyClaw
swift build          # debug build
swift run MyClaw     # run the app
swift build -c release  # release build
```

## Key conventions

- All data is filesystem-based: JSONL indexes, transcript files, launchd plists, wrapper scripts. No database.
- Job discovery filters to scripts in `~/.claude/scripts/` only.
- The "New Claude" flow uses Claude itself to generate wrapper scripts — don't replace this with a manual form.
- When spawning `claude` child processes, always clear the `CLAUDECODE` env var.

## Release workflow

- Bump `AppVersion.current` in `MyClaw/Sources/MyClaw/Services/HookInstaller.swift` for every PR.
- After merging a PR, create a GitHub release with the new version tag (e.g. `v1.2.0`).

## Past learnings

Skim `compounding-logs.md` when planning — it has gotchas from previous sessions (SwiftPM app quirks, macOS-specific issues, design decisions that went wrong the first time).
