# My Claw — Native macOS App Plan

## Context

Tiers 1 & 2 are done. We built:
- **SessionEnd hook** (`plugins/experimental/hooks/hooks.json` + `scripts/session-end-capture.sh`) — auto-captures every session to `~/.claude/job-monitor/jobs-index.jsonl`
- **`/schedule-claude` command** — sets up launchd wrapper scripts + plists
- **`/job-dashboard` command** — CLI dashboard with overview, transcript, stats, status modes

What's missing: a proper native Mac app with visual dashboards, menu bar, transcript viewer, job management, and the ability to launch new Claude sessions.

---

## Current Data Layer (what actually exists)

The app reads these files — all read-only, no registry, no structured job-logs:

| Data | Source | Format | What's in it |
|------|--------|--------|-------------|
| **Session index** | `~/.claude/job-monitor/jobs-index.jsonl` | JSONL | `session_id`, `transcript_path`, `cwd`, `reason`, `finished_at` (UTC) |
| **Transcripts** | `~/.claude/projects/.../<session-id>.jsonl` | JSONL | Full conversation: user prompts, assistant responses, tool calls, token usage per turn |
| **Scheduled jobs** | `~/Library/LaunchAgents/com.nityesh.*.plist` | XML plist | Label, script path, schedule (`StartCalendarInterval` or `StartInterval`) |
| **Wrapper scripts** | `~/.claude/scripts/*.sh` | Shell | Prompt, working directory, allowed tools, MCP config |
| **launchd status** | `launchctl list <label>` | Shell output | PID, last exit code, loaded state |

### Data gap: cost & duration

The index only has basic metadata. Cost/duration/turns are NOT in the index — they live inside transcripts. Two options:

**Option A: Enrich the hook (recommended pre-step)**
Enhance `session-end-capture.sh` to also read the transcript and extract:
- `num_turns` — count of assistant messages
- `duration_seconds` — first timestamp to last timestamp
- `total_input_tokens` / `total_output_tokens` — sum across all turns

This keeps the index as a fast lookup. The hook already has `transcript_path`, so it can `jq` the file.

**Option B: Parse transcripts on demand in the app**
App reads transcripts when user drills into a session. Slower for aggregate views (stats bar, charts). Fine for MVP.

**Recommendation:** Do Option A first (5-minute hook change), then the app can show stats without parsing every transcript.

---

## Pre-step: Enrich the SessionEnd Hook

**File:** `plugins/experimental/scripts/session-end-capture.sh`

Add after the existing `jq` extraction:
```bash
# Extract stats from transcript
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  NUM_TURNS=$(grep -c '"type":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
  FIRST_TS=$(head -1 "$TRANSCRIPT_PATH" | jq -r '.timestamp // empty' 2>/dev/null)
  LAST_TS=$(tail -1 "$TRANSCRIPT_PATH" | jq -r '.timestamp // empty' 2>/dev/null)
  # Sum tokens from assistant messages
  TOTAL_INPUT=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null | paste -sd+ | bc)
  TOTAL_OUTPUT=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" | jq -r '.message.usage.output_tokens // 0' 2>/dev/null | paste -sd+ | bc)
fi
```

New index entry format:
```json
{
  "session_id": "abc-123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/nityesh/...",
  "reason": "other",
  "finished_at": "2026-02-24T03:30:00Z",
  "num_turns": 3,
  "started_at": "2026-02-24T03:29:15Z",
  "total_input_tokens": 28000,
  "total_output_tokens": 1200
}
```

---

## Native macOS App — "My Claw"

**Location:** `~/Documents/Github/my-claw/MyClaw/`

### Tech stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (targeting macOS 13+)
- **Charts:** Swift Charts framework (native)
- **Build:** Swift Package Manager — `swift build` from CLI, no Xcode IDE needed
- **File watching:** DispatchSource on `~/.claude/job-monitor/jobs-index.jsonl`
- **Shell integration:** Process API for `claude -p` and `launchctl`
- **Notifications:** UserNotificationCenter
- **Dependencies:** Zero. Pure Apple frameworks.

### App structure

```
MyClaw/
├── Package.swift
├── Sources/
│   └── MyClaw/
│       ├── MyClawApp.swift         # @main entry, menu bar + main window
│       │
│       ├── Models/
│       │   ├── Job.swift                     # Discovered job (from plist + script parsing)
│       │   ├── SessionRun.swift              # Individual session run (from index)
│       │   ├── TranscriptEntry.swift         # Parsed transcript turn
│       │   └── AppSettings.swift             # User preferences
│       │
│       ├── Services/
│       │   ├── DataStore.swift               # Filesystem discovery: index, plists, scripts
│       │   ├── FileMonitor.swift             # Watches jobs-index.jsonl for new entries
│       │   ├── TranscriptParser.swift        # Parses .jsonl transcripts into structured turns
│       │   ├── ClaudeCLI.swift               # Invokes claude -p, streams output
│       │   ├── LaunchdManager.swift          # Discovers/creates/loads/unloads plists
│       │   └── NotificationService.swift     # macOS notifications on job complete/fail
│       │
│       ├── Views/
│       │   ├── Dashboard/
│       │   │   ├── DashboardView.swift       # Main dashboard with stats + session list
│       │   │   ├── JobCardView.swift         # Scheduled job card (status, schedule, last run)
│       │   │   ├── StatsBarView.swift        # Top stats: sessions today, success rate, total tokens
│       │   │   └── TimelineView.swift        # 7-day visual timeline of all runs
│       │   │
│       │   ├── JobDetail/
│       │   │   ├── JobDetailView.swift       # Detail page for a scheduled job
│       │   │   ├── RunHistoryTable.swift     # Sortable table of past runs
│       │   │   └── RunCharts.swift           # Duration + token trend charts
│       │   │
│       │   ├── Transcript/
│       │   │   ├── TranscriptView.swift      # Chat-bubble style transcript viewer
│       │   │   ├── MessageBubble.swift       # Individual message (user/assistant/tool)
│       │   │   └── ToolCallCard.swift        # Expandable tool call detail
│       │   │
│       │   ├── NewSession/
│       │   │   ├── NewSessionView.swift      # Create and launch a new Claude session
│       │   │   ├── PromptEditor.swift        # Edit prompt, pick tools, set CWD
│       │   │   └── LiveOutputView.swift      # Stream claude -p output in real-time
│       │   │
│       │   ├── JobManager/
│       │   │   ├── JobManagerView.swift      # Create/edit/delete scheduled jobs
│       │   │   ├── JobEditorSheet.swift      # Form: name, prompt, schedule, tools, cwd
│       │   │   └── SchedulePicker.swift      # Visual schedule selector
│       │   │
│       │   └── Settings/
│       │       └── SettingsView.swift        # Paths, notifications, preferences
│       │
│       └── Utilities/
│           ├── JSONLParser.swift             # Parse .jsonl files line by line
│           ├── PlistParser.swift             # Parse launchd plists for schedule info
│           ├── DateFormatting.swift          # UTC→local conversion, relative timestamps
│           └── StatusColor.swift             # Green/red/yellow/gray status mapping
│
└── Tests/
    └── MyClawTests/
        ├── DataStoreTests.swift
        ├── JSONLParserTests.swift
        ├── TranscriptParserTests.swift
        └── PlistParserTests.swift
```

Key changes from original plan:
- `DataStore.swift` — filesystem discovery (scan plists + scripts), NOT registry reading
- `FileMonitor.swift` — watches `jobs-index.jsonl`, NOT `job-logs/` directory
- `TranscriptParser.swift` — NEW: parses `.jsonl` transcripts into structured turns
- `PlistParser.swift` — NEW: extracts schedule info from launchd XML plists
- `Job.swift` — "Discovered" job model (from plist + script), NOT "Registered"
- `SessionRun.swift` renamed from `JobRun.swift` — sessions are the primary unit, not jobs
- Stats show tokens instead of cost (tokens are in the data, cost requires pricing knowledge)

### Feature breakdown

#### Menu Bar
- Persistent icon in macOS menu bar
- Color-coded: green (all jobs healthy), red (recent failure), gray (no jobs)
- Click to open dropdown: quick stats + last 3 sessions + "Open Dashboard"
- Badge count of failed runs in last 24h

#### Dashboard (main window)
- **Stats bar** at top: Scheduled Jobs | Sessions Today | Success Rate | Tokens Today
- **Scheduled jobs section**: cards showing job name, schedule, loaded status, last exit code
- **Recent sessions section**: list of recent sessions from the index with CWD, timestamp, reason
- **7-day timeline** at bottom: horizontal lanes per job, colored blocks per run

#### Job Detail
- Click a scheduled job card to navigate here
- Job metadata: name, prompt (extracted from wrapper script), schedule, CWD
- **Associated sessions**: matches sessions from the index by CWD + timing
- **Charts**: run frequency, duration trends (if enriched hook data available)

#### Transcript Viewer
- Click any session to see full conversation
- Chat bubbles: user messages on right, Claude responses on left
- Tool calls as collapsible cards with tool name, input summary, output summary
- Token usage summary at bottom
- Copy button for individual messages

#### New Session
- "New Session" button in toolbar
- Enter prompt or pick from discovered wrapper scripts
- Configure: working directory, allowed tools
- Runs `claude -p` via Process API, streams output live
- Auto-appears in session history when done (hook captures it)

#### Job Manager
- Create new scheduled job: name, prompt, schedule, tools, CWD
- Generates wrapper script in `~/.claude/scripts/` + plist in `~/Library/LaunchAgents/`
- Toggle jobs on/off (`launchctl load/unload`)
- Edit/delete existing jobs
- Visual schedule picker: time + day-of-week + frequency

#### Notifications
- Native macOS notification when a session completes
- Different style for success vs failure
- Configurable per-job notification preferences

### How the app discovers data

```
On launch:
  1. Scan ~/Library/LaunchAgents/com.nityesh.*.plist
     → parse each: label, script path, schedule
  2. Scan ~/.claude/scripts/*.sh
     → parse each: prompt, CWD, allowed tools
  3. Read ~/.claude/job-monitor/jobs-index.jsonl
     → load all session entries
  4. For each plist label: launchctl list <label>
     → get loaded status + last exit code

On file change (FileMonitor):
  - Watch jobs-index.jsonl for appends
  - When new line appears → parse it, add to session list, update UI
  - DispatchSource.makeFileSystemObjectSource on the file descriptor
```

### Building and running

```bash
cd ~/Documents/Github/my-claw
swift build                    # Build
swift run MyClaw               # Run
swift build -c release         # Release build
# Binary: .build/release/MyClaw
```

### Implementation phases

| Phase | What | Key files |
|-------|------|-----------|
| 0 | **Enrich SessionEnd hook** — add num_turns, started_at, tokens to index | `session-end-capture.sh` |
| 1 | **Scaffolding** — Package.swift, models, DataStore, JSONLParser, PlistParser | Models/, Services/DataStore.swift, Utilities/ |
| 2 | **Dashboard** — main window, stats bar, job cards, session list | Views/Dashboard/ |
| 3 | **Transcript viewer** — parse transcripts, chat bubbles, tool cards | Views/Transcript/, Services/TranscriptParser.swift |
| 4 | **Job detail** — associated sessions, run history table, charts | Views/JobDetail/ |
| 5 | **New session** — invoke claude -p, stream output, live view | Views/NewSession/, Services/ClaudeCLI.swift |
| 6 | **Job manager** — create/edit/delete scheduled jobs via GUI | Views/JobManager/, Services/LaunchdManager.swift |
| 7 | **Menu bar + notifications + file watching** | MyClawApp.swift, Services/FileMonitor.swift, NotificationService.swift |
| 8 | **Polish** — error handling, edge cases, testing | Tests/ |

**MVP (phases 0-3):** Enriched data + dashboard + transcript viewer. Usable in ~2-3 sessions.

### Verification

1. `swift build` succeeds with no errors
2. `swift run MyClaw` opens a window showing discovered jobs and sessions
3. Run `/schedule-claude` to create a test job, verify it appears in the app
4. Click a session → transcript viewer shows the conversation correctly
5. Trigger a scheduled job → verify the app updates live (FileMonitor picks up the new index entry)
6. Create a new session from the app → verify `claude -p` runs and output streams
