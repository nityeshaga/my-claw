# Compounding Logs

Tacit knowledge accumulated from building this project. Friction moments, gotchas, and heuristics worth remembering.

---

## 2026-02-25 — Initial build session

### SwiftPM executable is not a macOS app

`swift run` produces a bare executable, not a bundled `.app`. This causes a cluster of related issues:

- `UNUserNotificationCenter` crashes because it needs a bundle proxy. Use `osascript` for notifications instead.
- Keyboard input doesn't work unless you set `NSApp.setActivationPolicy(.regular)` — do this in `onAppear`, not `init` (NSApp is nil at init time).
- Any API that assumes a proper app bundle will fail. Always test with `swift run`, not just `swift build`.

### Inherited CLAUDECODE env var breaks child processes

When the app spawns `claude -p`, it inherits the environment of whatever launched it. If launched from within a Claude Code session, `CLAUDECODE` is set and the child process refuses to run with "cannot be launched inside another Claude Code session." Always clear this env var when creating `Process` instances that call claude.

### Filter shared directories by what you own

Scanning `~/Library/LaunchAgents/com.*.plist` picks up everything — Google Updater, Keystone, etc. Filter by your own data path (`~/.claude/scripts/`) instead of relying on naming conventions.

### macOS paste command differs from Linux

`paste -sd+` works on Linux but fails silently on macOS. Use `awk '{s+=$1} END{print s+0}'` for summing numbers from a pipe.

### When replicating an existing flow, study the UX not the output

The `/schedule-claude` command's value is that Claude *reasons* about what tools and MCP config are needed. Building a manual form with fields for tools/mcp-config misses the entire point. When told to replicate something, understand why users like it, not just what files it produces.

### TextEditor has focus issues in SwiftUI sheets

`TextEditor` inside a `.sheet()` doesn't receive keyboard focus reliably. Use `TextField("placeholder", text: $binding, axis: .vertical)` with `.lineLimit(4...10)` instead for multiline input in sheets.
