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
- Create new jobs with a visual editor: name, prompt, working directory, schedule, allowed tools
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

### 1. Install the SessionEnd hook

My Claw reads session data from `~/.claude/job-monitor/jobs-index.jsonl`, which is populated by a SessionEnd hook. If you're using the [every-consulting experimental plugin](https://github.com/every-consulting), this is already configured.

Otherwise, create `~/.claude/hooks.json` (or add to your existing hooks) with:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "type": "command",
        "command": "/path/to/session-end-capture.sh"
      }
    ]
  }
}
```

The hook script captures each session's ID, transcript path, working directory, finish reason, timestamps, turn count, and token usage into the JSONL index.

### 2. Build and run

```bash
cd MyClaw
swift run MyClaw
```

Or build a release binary:

```bash
cd MyClaw
swift build -c release
# Binary is at .build/release/MyClaw
```

### 3. Schedule jobs (optional)

To create scheduled Claude jobs that My Claw can monitor, use the Job Manager (sidebar > Scheduled Jobs > +) or create them manually:

1. Write a wrapper script in `~/.claude/scripts/my-job.sh`:
```bash
#!/bin/bash
LOG="$HOME/.my-job.log"
echo "=== Started at $(date) ===" >> "$LOG"
cd /path/to/project

~/.local/bin/claude -p "Your prompt here" \
  --dangerously-skip-permissions >> "$LOG" 2>&1

echo "=== Finished at $(date) ===" >> "$LOG"
```

2. Create a launchd plist in `~/Library/LaunchAgents/com.yourname.my-job.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourname.my-job</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/yourname/.claude/scripts/my-job.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

3. Load it: `launchctl load ~/Library/LaunchAgents/com.yourname.my-job.plist`

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
| Scheduled jobs | `~/Library/LaunchAgents/com.*.plist` | XML plist |
| Wrapper scripts | `~/.claude/scripts/*.sh` | Bash |
| Job status | `launchctl list <label>` | CLI |

## Tech Stack

- **SwiftUI** — all views, no AppKit/UIKit
- **Swift Charts** — token usage and duration trend charts
- **DispatchSource** — file system monitoring for live index updates
- **launchd** — job scheduling via standard macOS launch agents
- **Zero dependencies** — pure Apple frameworks, no SPM packages
