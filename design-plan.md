# Arcade UI Redesign Plan

## Design Philosophy

Five principles guiding every decision:

1. **Information hierarchy through light** — In a dark UI, the brightest thing wins attention. Glow and color intensity direct the eye to what matters most (running jobs, errors, primary actions).

2. **Ambient metaphor, not literal** — The claw machine feel comes from the color palette (neon on dark), typography (monospace = arcade marquee), and glow effects (CRT phosphor luminance). We don't plaster pixel claws everywhere.

3. **Status is color, activity is glow** — Static states get flat colored indicators. Active/running states get soft glow halos. This creates a natural visual heartbeat.

4. **Monospace = machine, proportional = human** — Headings, labels, data values, timestamps all in monospace (this is a machine monitoring tool). Descriptions and body text stay in system font (for humans to read).

5. **Neon accent hierarchy** — Not everything is neon. Coral for navigation and CTAs. Cyan for data emphasis. Amber for stats/tokens. Purple for charts. This prevents visual chaos.

---

## Design Tokens

### Color Palette

**Derived from the app icon** (arcade claw + terminal cursor + Anthropic warm tones):

| Token | Hex | Usage |
|-------|-----|-------|
| `coral` | #FF6B6B | Primary accent — CTAs, navigation selection, primary buttons |
| `terracotta` | #E07A5F | Secondary warm — borders, secondary elements |
| `cream` | #FFF1E6 | Light text highlights, hover states |
| `neonCyan` | #4ECDC4 | Data emphasis — session counts, info states |
| `neonAmber` | #FFD93D | Stats, token counts, warning states |
| `neonPurple` | #A78BFA | Charts, decorative accents |

**Semantic (built from the neon palette):**

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | #34D399 | Running jobs, successful sessions, loaded toggles |
| `error` | #F87171 | Failed jobs, errors, destructive actions |
| `warning` | #FBBF24 | Warnings, prompt_input_exit |

**Backgrounds:**

Force `.preferredColorScheme(.dark)` on the main window. Use system dark mode backgrounds for window chrome and sidebar. Custom backgrounds only for cards and input areas:

| Token | Description |
|-------|-------------|
| `surfaceDark` | Card backgrounds — `Color.white.opacity(0.04)` |
| `surfaceElevated` | Hover/active cards — `Color.white.opacity(0.07)` |
| `surfaceInput` | Text fields — `Color.white.opacity(0.03)` |

**Text:**

| Token | Opacity |
|-------|---------|
| `textPrimary` | `.white.opacity(0.92)` |
| `textSecondary` | `.white.opacity(0.55)` |
| `textTertiary` | `.white.opacity(0.3)` |

### Typography

| Token | Font | Usage |
|-------|------|-------|
| `displayMono` | `.system(.largeTitle, design: .monospaced).bold()` | Empty state icons/titles |
| `titleMono` | `.system(.title2, design: .monospaced).weight(.semibold)` | Section titles |
| `headingMono` | `.system(.headline, design: .monospaced).weight(.medium)` | Card titles, labels |
| `bodyText` | `.system(.body)` | Descriptions, body text |
| `dataMono` | `.system(.callout, design: .monospaced)` | Values, counts, IDs |
| `captionMono` | `.system(.caption, design: .monospaced)` | Timestamps, metadata |
| `codeMono` | `.system(.caption2, design: .monospaced)` | Code, JSON, tool details |

### Glow System

| Effect | Implementation |
|--------|----------------|
| Active glow | `.shadow(color: X.opacity(0.4), radius: 8)` — running jobs, live sessions |
| Subtle glow | `.shadow(color: X.opacity(0.25), radius: 4)` — status indicators, badges |
| Pulse animation | `Animation.easeInOut(duration: 1.2).repeatForever()` on opacity — running status dots |

### Card System

All cards: dark surface background + 1px border at accent color 20% opacity + rounded corners (10pt).

- **Default card**: `surfaceDark` bg + `quaternary` border
- **Status card**: Same + 3pt colored left border (status color)
- **Active card**: Same + glow shadow in status color
- **Hover state**: `surfaceElevated` bg

### Spacing (unchanged)

Keep current spacing values — they work well. The redesign is about color/type/glow, not layout restructuring.

---

## Implementation Phases

### Phase 1: Design Foundation
**New files:**
- `MyClaw/Sources/MyClaw/Theme/ArcadeTheme.swift` — All color, font, and spacing tokens as static properties on a `Theme` enum
- `MyClaw/Sources/MyClaw/Theme/ArcadeModifiers.swift` — Reusable ViewModifiers: `.arcadeCard()`, `.glowEffect(color:)`, `.pulsingGlow(color:)`, `.arcadeHeading()`, status indicator component

**Modified files:**
- `MyClawApp.swift` — Add `.preferredColorScheme(.dark)` to WindowGroup
- `StatusColor.swift` — Remap all status colors to the new palette (success→#34D399, error→#F87171, etc.)

### Phase 2: Dashboard
**Modified files:**
- `DashboardView.swift` — Dark background, section headers in monospace
- `StatsBarView.swift` — Neon-accented stat cards with colored icons, glow on hover, monospace values
- `JobCardView.swift` — Dark card with status-colored left border, monospace job names, glow for running jobs
- `SessionListView.swift` — Dark rows with subtle colored accents, monospace data columns
- `TimelineView.swift` — Neon gradient chart fills (cyan, purple), dark grid lines

### Phase 3: Transcript & Job Detail
**Modified files:**
- `TranscriptView.swift` — Dark background
- `MessageBubble.swift` — User bubbles: coral-tinted dark bg. Assistant bubbles: cyan-tinted dark bg. Monospace role labels.
- `ToolCallCard.swift` — Amber/orange-tinted border, dark bg, monospace tool names
- `JobDetailView.swift` — Monospace headings, dark metadata cards, status glow
- `RunHistoryTable.swift` — Dark table with arcade typography
- `RunCharts.swift` — Neon gradient chart fills (cyan for tokens, amber for duration)

### Phase 4: Remaining Views
**Modified files:**
- `JobManagerView.swift` — Dark list, toggle styling, status indicators with glow
- `JobEditorSheet.swift` — Dark form inputs, coral accent buttons, monospace labels
- `SchedulePicker.swift` — Styled segmented control
- `NewSessionView.swift` — Dark layout
- `PromptEditor.swift` — Dark input with subtle border glow on focus
- `LiveOutputView.swift` — Terminal-style: monospace text, dark bg, subtle green tint
- `SettingsView.swift` — Dark forms, monospace labels
- `MyClawApp.swift` — Sidebar labels in monospace, coral selection accent, MenuBarView styling

### Phase 5: Polish & Animation
- Add pulsing glow animation to running job status indicators
- Smooth `.animation(.easeInOut(duration: 0.2))` on card hover states
- Verify all views are consistent — no stray system blue or flat styling
- Test empty states, loading states, error states all look good in arcade theme
- Build and verify clean compilation

---

## What We're NOT Doing

- No custom fonts (stick to SF Mono / system)
- No pixel art or literal arcade graphics
- No CRT scanline overlays (too gimmicky for accented approach)
- No layout restructuring — same navigation, same component hierarchy
- No new features — purely visual redesign
- No light mode support — dark only
