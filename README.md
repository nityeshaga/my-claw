# My Claw

A native macOS app for monitoring and managing [Claude Code](https://docs.anthropic.com/en/docs/claude-code) scheduled jobs and sessions.

My Claw reads the same filesystem data that Claude Code produces — JSONL session indexes, transcript files, launchd plists, and wrapper scripts — and presents it in a clean native interface with live updates.

## Features

**Dashboard**
- Stats bar: scheduled job count, sessions today, success rate, token usage
- Job cards showing status, schedule, and prompt preview
- Recent sessions table with project name, turns, tokens, duration, and relative timestamps
- Click any session to open its full transcript

**Transcript Viewer**
- Chat-bubble UI for user/assistant messages
- Collapsible tool call cards showing tool name, input summary, and full JSON
- Tool result cards with error/success indicators
- Token usage footer (input/output totals)

**Job Manager**
- List all Claude scheduled jobs with load/unload toggles
- **AI-powered job creation**: describe what you want in plain English, pick a schedule, and Claude generates the complete wrapper script with the right `--allowedTools`, `--mcp-config`, working directory, and flags — just like the `/schedule-claude` command
- Review the generated script before confirming
- Schedule picker: interval (every N minutes), daily at time, or specific weekdays
- Delete jobs (unloads from launchd and removes script + plist files)

**Job Detail**
- Full job metadata: label, schedule, working directory, allowed tools, prompt
- Run history table of associated sessions
- Token usage and duration charts (last 10 runs)
- "Run Now" button to trigger immediately

**New Session**
- Launch `claude -p` from the app with a custom prompt
- Configure working directory and allowed tools
- Live streaming output view
- Stop button to terminate running sessions

**Menu Bar**
- Persistent menu bar icon with status tint (green = healthy, red = recent failure)
- Quick stats and recent sessions at a glance
- Launch new sessions or open the dashboard from the menu bar

**Settings**
- Configure paths: Claude binary, index file, scripts directory
- Notification preferences: enable/disable, failure-only mode

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed at `~/.local/bin/claude`

## Setup

### 1. Install the app

#### Download (recommended)

1. Go to the [latest release](https://github.com/nityeshaga/my-claw/releases/latest)
2. Download `My.Claw.zip`
3. Unzip and drag `My Claw.app` to your `/Applications` folder
4. Remove the macOS quarantine flag (required for unsigned apps downloaded from the internet):
   ```bash
   xattr -cr "/Applications/My Claw.app"
   ```
5. Open the app. If macOS still warns about an unidentified developer, right-click the app, click **Open**, then click **Open** again.

The app checks for updates automatically. You can also check manually via **My Claw > Check for Updates...** in the menu bar.

#### Build from source

```bash
git clone https://github.com/nityeshaga/my-claw.git
cd my-claw
./scripts/bundle-app.sh
cp -r "dist/My Claw.app" /Applications/
```

For development, you can run directly without installing:
```bash
cd MyClaw
swift run MyClaw
```

### 2. Session tracking

On first launch, My Claw automatically installs a Claude Code `SessionEnd` hook that captures session metadata (tokens, turns, duration, etc.) into `~/.claude/job-monitor/jobs-index.jsonl`. No manual configuration needed — the hook is kept up to date automatically.

### 3. Schedule jobs

Click **"New Claude"** in the sidebar and describe what you want:

> "Check Granola for new meetings every 30 minutes and summarize them"

> "Search for AI lab announcements daily and draft an email about what's relevant to our consulting"

Pick a schedule, hit **Generate Job**, and Claude will create the complete wrapper script with the right tools, MCP config, and working directory. Review it, then click **Create & Load**.

Under the hood, this creates:
- A wrapper script at `~/.claude/scripts/<name>.sh`
- A launchd plist at `~/Library/LaunchAgents/com.<username>.<name>.plist`
- Loads it into launchd immediately

You can also create jobs manually if you prefer — see the [schedule-claude command](https://github.com/every-consulting) for the manual pattern.

## Architecture

```
MyClaw/Sources/MyClaw/
├── MyClawApp.swift              # App entry, menu bar, sidebar navigation
├── Models/
│   ├── SessionRun.swift         # Session index entry (from jobs-index.jsonl)
│   ├── Job.swift                # Scheduled job (from plist + wrapper script)
│   ├── TranscriptEntry.swift    # Single transcript message/tool call
│   └── AppSettings.swift        # User preferences (persisted via UserDefaults)
├── Services/
│   ├── DataStore.swift          # Central data: discovers jobs, loads sessions
│   ├── FileMonitor.swift        # DispatchSource file watcher for live updates
│   ├── TranscriptParser.swift   # Parses .jsonl transcripts into structured entries
│   ├── ScriptParser.swift       # Extracts prompt/cwd/tools from wrapper scripts
│   ├── ClaudeCLI.swift          # Launches claude -p and streams output
│   ├── LaunchdManager.swift     # Load/unload/create/delete launchd jobs
│   └── NotificationService.swift # macOS notifications via osascript
├── Utilities/
│   ├── JSONLParser.swift        # Generic JSONL parser with tail-reading support
│   ├── PlistParser.swift        # Parses launchd plists for schedule info
│   ├── DateFormatting.swift     # ISO 8601 parsing, relative times, durations
│   └── StatusColor.swift        # Consistent status-to-color mapping
└── Views/
    ├── Dashboard/               # Stats bar, job cards, session list, timeline
    ├── Transcript/              # Chat bubbles, tool call cards, result cards
    ├── JobDetail/               # Metadata, run history table, charts
    ├── JobManager/              # Job list, editor sheet, schedule picker
    ├── NewSession/              # Prompt editor, live output view
    └── Settings/                # Path and notification configuration
```

**Data sources** (all read from the filesystem, no database):

| What | Path | Format |
|------|------|--------|
| Session index | `~/.claude/job-monitor/jobs-index.jsonl` | JSONL |
| Transcripts | `~/.claude/projects/.../<session-id>.jsonl` | JSONL |
| Scheduled jobs | `~/Library/LaunchAgents/com.*.plist` (filtered to `~/.claude/scripts/`) | XML plist |
| Wrapper scripts | `~/.claude/scripts/*.sh` | Bash |
| Job status | `launchctl list <label>` | CLI |

## Tech Stack

- **SwiftUI** — all views, no AppKit/UIKit
- **Swift Charts** — token usage and duration trend charts
- **DispatchSource** — file system monitoring for live index updates
- **launchd** — job scheduling via standard macOS launch agents
- **Zero dependencies** — pure Apple frameworks, no SPM packages
