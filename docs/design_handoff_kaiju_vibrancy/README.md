# Handoff: Kaiju — macOS issue-tracker (Translucent Vibrancy)

## Overview

Kaiju is a Mac-native issue-tracker client (Jira-style) styled after modern
macOS Tahoe / "Liquid Glass". The selected direction is **Translucent
Vibrancy**: a floating inset sidebar with NSVisualEffect backing, a soft
gradient wallpaper behind the window, and translucent issue cards on a Kanban
board. Sleeker and quieter than Jira on the web; the chrome gets out of the
way of the content.

## About the design files

The files in this bundle (`Kaiju.html` and `source/*.jsx`) are **design
references created in HTML/React**. They are a visual + behavioral spec — not
production code to copy. The task is to **recreate the Vibrancy variation
natively in SwiftUI/AppKit** using the project's existing patterns and
libraries. The HTML simulates macOS materials with CSS `backdrop-filter` and
gradient backgrounds; native should use real `NSVisualEffectView` materials,
SF Symbols, and standard split-view chrome.

Open `Kaiju.html` in a browser to see the live prototype with all three
variations on a canvas. Use the focus button on the Vibrancy artboard to view
it full-size.

## Fidelity

**High-fidelity.** Spacing, type scale, color values, and interactions are
all final-quality. Use them as targets when the platform supports them; fall
back to native equivalents (SF Symbols, system materials, system fonts) where
that produces a more authentic Mac feel.

## Target environment

- **macOS 14+ (Sonoma) or 15+ (Sequoia)** — needs visual-effect materials,
  inset sidebar, sheet presentation.
- **SwiftUI-first**, with `NSViewRepresentable` bridges where SwiftUI lacks a
  control (e.g. NSVisualEffectView material variants, NSSearchField).
- Use `NavigationSplitView` for the sidebar / detail layout — it gives you
  the inset-floating sidebar appearance for free on macOS 14+.

## Screens / views

The Vibrancy app is one window with three regions:

### 1. Sidebar (220 px wide, floating inset)
A translucent panel inside the window edge. Sections, in order:
- **Workspace switcher** — squircle icon (gradient, 22 px) + workspace name
  + chevron. Tap opens a workspace picker (out of scope here).
- **My Work** — Inbox, Assigned, Created, Subscribed. Each row has a
  monoline 14 px icon, label (13 px / 500), and a right-aligned numeric
  badge.
- **Workspace** — Board, All issues, Sprints, Roadmap, Projects.
- **Filters** — saved filters, each prefixed with a 8 px colored square.
- **User pill** at bottom — avatar, name, "Online" status, settings cog.

Active row is highlighted with `accent @ 18% opacity` background and accent
foreground for icon + label. Sidebar background uses
`.windowBackground` material; in SwiftUI, set
`.toolbar(.hidden, for: .windowToolbar)` on the sidebar's column and let
`NavigationSplitView` provide the material.

### 2. Toolbar (above board)
Single row, no traditional title bar (traffic lights live inside the
sidebar). Contents left → right:
- **Title block** — "Board" (17 px, weight 700, letter-spacing −0.3) ·
  "Web Platform" subtitle · "Sprint 24" pill (11 px, weight 500).
- **Filter input** — 28 px tall, 8 px corner radius, glass material, search
  icon left, "Filter issues…" placeholder.
- **⌘K pill** — opens command palette.
- **Filter pill** — funnel icon.
- **Avatar stack** — overlapping circular monograms of recent collaborators.
- **New button** — accent fill, white text, "New", with `Icons.Plus`.

### 3. Board
Five columns: Backlog, To Do, In Progress, In Review, Done. Each column:
- 12 px corner radius, hairline border, very subtle tinted fill (≈3% black
  on light, 2.5% white on dark).
- Header: status donut (14 px, color matches status), name (12 px / 600),
  count badge (subtle), `+` button on right.
- Cards: 11 px padding, 8 px corners, glass material card.

### Issue card structure
```
┌─────────────────────────────────────┐
│ [priority] WEB-256        [avatar]  │  ← row 1: meta
│                                     │
│ Command palette: fuzzy match by    │  ← row 2: title (12.5px / 500)
│ alias                               │
│                                     │
│ [feature]            💬 8       5   │  ← row 3: labels • comments • estimate
└─────────────────────────────────────┘
```

### 4. Inspector (right panel, 360 px)
Slides in from the right when an issue is clicked. Contents:
- Header: issue ID + close button.
- Title (18 px / 600).
- Properties block: Status (button, opens dropdown), Priority, Assignee,
  Labels, Estimate, Created. Each row: 88 px label column on left, value
  on right. Hairline divider top + bottom.
- Description (13 px / 1.6 line-height, supports paragraphs).
- Activity feed: avatar + actor + verb + meta pill + relative time.
- Comment composer at bottom: avatar + input + send arrow.

## Interactions & behavior

| Interaction | Behavior |
|---|---|
| Drag card | Drag any card between columns; status updates on drop. Use SwiftUI's `.draggable` / `.dropDestination` with a custom `Transferable` issue payload. |
| Click card | Slide inspector in from the right (220 ms, ease-out). Use `.inspector` modifier or a custom `NavigationSplitView` trailing column. |
| ⌘K | Open command palette modal. Implement as a sheet with `.presentationBackground(.ultraThinMaterial)` or a floating window. |
| Esc | Close palette and inspector. |
| Filter input | Live-filters cards in all columns by title or ID. |
| Status dropdown | In inspector, click status pill → menu with all 5 statuses. |

### Animations
- Inspector slide: 220 ms, cubic-bezier(.2, .7, .3, 1), translateX 20 → 0 + opacity 0 → 1.
- Card drag: scale 1.02 + 12 px shadow on the drag image.
- Column hover-while-dragging: column tint shifts to `status.color @ 8%`.

## State

Single source-of-truth view model:

```swift
@Observable
final class BoardModel {
    var issues: [Issue]
    var selectedIssueID: Issue.ID?
    var filterText: String = ""
    var paletteOpen: Bool = false
    var activeNav: NavItem = .board
}
```

`Issue` should mirror the JS shape in `source/data.jsx`:

```swift
struct Issue: Identifiable, Codable, Hashable {
    let id: String                 // "WEB-256"
    var title: String
    var status: Status             // enum: backlog, todo, doing, review, done
    var priority: Priority         // enum: urgent, high, med, low, none
    var assigneeID: User.ID?
    var labels: [Label]
    var estimate: Int
    var comments: Int
    var created: Date
}
```

## Design tokens

### Colors (light)
- Window wallpaper: `radial-gradient(ellipse 1200×800 at 20% 10%, #d8e8ff 0%, #efe4ff 50%, #ffe9f1 100%)`
  — implement as a tinted `LinearGradient`/`RadialGradient` underneath the window content; the translucent sidebar/cards will pick up the color.
- Foreground primary: `rgba(0,0,0,0.86)`
- Foreground muted: `rgba(0,0,0,0.50)`
- Foreground subtle: `rgba(0,0,0,0.38)`
- Hairline: `rgba(0,0,0,0.06)`
- Card material: `.regularMaterial` (≈ 85% white tint in HTML)
- Sidebar material: `.sidebar` (≈ 45% white tint)
- Default accent: `#5E5CE6` (system indigo)

### Colors (dark)
- Wallpaper: `radial-gradient(ellipse 1200×800 at 20% 10%, #2a3454 0%, #1a1a2e 50%, #0f0f1a 100%)`
- Foreground primary: `rgba(255,255,255,0.92)`
- Foreground muted: `rgba(255,255,255,0.55)`
- Hairline: `rgba(255,255,255,0.08)`

### Status colors
| Status | Hex |
|---|---|
| Backlog | #94A3B8 |
| To Do | #64748B |
| In Progress | #3B82F6 |
| In Review | #A855F7 |
| Done | #10B981 |

### Priority colors
| Priority | Hex | Glyph |
|---|---|---|
| Urgent | #DC2626 | Filled square + `!` |
| High | #EA580C | 3-bar icon |
| Medium | #CA8A04 | 2-bar icon |
| Low | #65A30D | 1-bar icon |
| None | #6B7280 | Dashed line |

### Label palette
See `source/data.jsx` `KAIJU_LABELS` — each label is `{ name, color }`. Render as a chip with `color @ 12%` background, `color @ 25%` border, `color` foreground.

### Typography
- Family: SF Pro Text (system default on macOS — use `Font.system`).
- Sizes used: 10, 10.5, 11, 12, 12.5, 13, 17, 18.
- All weights ≤ 700.

### Spacing
- Window padding: 10
- Card padding: 9 / 11
- Column gap: 10
- Card-to-card gap: 6
- Sidebar inset: 8 from window edge

### Radii
- Window: 12 (system default — let macOS draw it)
- Sidebar panel: 14
- Cards: 8
- Pills/buttons: 7-8
- Donut/dot: round

### Shadows
- Window: system
- Sidebar floating: `0 8px 32px rgba(0,0,0,0.06)` + inset 1 px highlight
- Card: `0 1px 2px rgba(0,0,0,0.04)` + inset 1 px highlight (drop in dark mode)
- Inspector panel: `-8px 0 32px rgba(0,0,0,0.12)`

## SwiftUI implementation notes

- Use `NavigationSplitView(columnVisibility:)` with a sidebar, content (board), and `.inspector` for the issue panel. This gives you the inset floating sidebar on macOS 14+.
- For the wallpaper-behind-window effect, set the window background to clear and place a `LinearGradient`/`RadialGradient` behind your content — `.background(GradientView())` on the root view, with the window styled `.windowStyle(.hiddenTitleBar)` and `.windowBackgroundDragBehavior(.enabled)`.
- Replace custom SVG icons with **SF Symbols**: `tray`, `person.crop.circle`, `square.grid.2x2`, `list.bullet`, `timer`, `map`, `folder`, `paperplane.circle`, `command`, `chevron.right`. The handoff icons (`primitives.jsx → Icons`) name the intent — pick the closest SF Symbol.
- Use `.material(.regular)` / `.material(.thick)` / `.material(.sidebar)` for backing fills.
- Command palette: `Window` scene + `.windowResizability(.contentSize)`, or a sheet on the main window with `.presentationBackground(.thinMaterial)`. Filtering is straightforward `String.contains` against `id` and `title`.
- Drag and drop: conform `Issue` to `Transferable` with a custom `UTType.kaijuIssue`; `.draggable(issue)` on the card, `.dropDestination(for: Issue.self)` on each column with a closure that mutates `issue.status`.

## Files in this bundle

```
design_handoff_kaiju_vibrancy/
├── README.md                       ← this file
├── Kaiju.html                      ← live prototype, all three variations
└── source/
    ├── data.jsx                    ← sample issues, users, statuses, priorities
    ├── primitives.jsx              ← Icons, Avatar, StatusDot, PriorityIcon, LabelChip
    ├── app-shell.jsx               ← shared logic: drag/drop, command palette, inspector
    ├── variation-vibrancy.jsx      ← THE ONE TO BUILD — Translucent Vibrancy
    ├── variation-mono.jsx          ← reference only
    ├── variation-pro.jsx           ← reference only
    ├── design-canvas.jsx           ← canvas wrapper (not part of the app)
    └── tweaks-panel.jsx            ← tweaks UI (not part of the app)
```

## Suggested implementation order

1. **Skeleton.** `NavigationSplitView` with sidebar + main pane. Hard-code one column of static cards. Get the inset sidebar + window chrome looking right.
2. **Sample data.** Port `KAIJU_ISSUES`, `KAIJU_STATUSES`, `KAIJU_PRIORITIES`, `KAIJU_USERS` from `source/data.jsx` into a `SampleData.swift`.
3. **Status donut + priority bars** as small `Canvas` or `Shape` views. These are the most distinctive iconography.
4. **Card view.** Match the 3-row structure exactly. Use `.background(.regularMaterial)`.
5. **Columns + drag/drop.**
6. **Inspector** as `.inspector` modifier. Properties grid + activity feed.
7. **Command palette** as a sheet.
8. **Filter input + ⌘K shortcut.**
9. **Polish** — accent color (read from system or pin to `#5E5CE6`), dark mode pass.

## What to ask the design team

- Real iconography pass — replace HTML mono-line icons with the chosen SF Symbol set, confirm with design.
- Empty states for each column.
- Onboarding / auth — out of scope here.
- Notifications, offline behavior, sync UI.
