# SwiftCLIKit — Development Guidelines

This project follows the Design-First TDD workflow defined in `development-guidelines/`.

## Session Start

Read documents in this order for full context recovery:
1. `development-guidelines/00_CORE_RULES/00_MASTER_PLAN.md` — Vision and priorities
2. `development-guidelines/00_CORE_RULES/01_CODING_RULES.md` — Forbidden patterns, safety rules
3. `development-guidelines/00_CORE_RULES/09_TEST_DRIVEN_DEVELOPMENT.md` — Testing contract
4. `development-guidelines/04_IMPLEMENTATION_CHECKLISTS/CURRENT_*.md` — Active tasks (if any)
5. Latest file in `development-guidelines/05_SUMMARIES/` — Where we left off (if any)

For quick recovery (same-day, simple bug fixes), read only items 4-5.

## Development Workflow

```
0. DESIGN   → Propose architecture (05_DESIGN_PROPOSAL.md)
1. RED      → Write failing tests first
2. GREEN    → Minimum code to pass
3. REFACTOR → Clean up, keep tests green
4. DOCUMENT → DocC comments and examples
5. VERIFY   → Run quality-gate (zero warnings/errors)
```

## Key Rules

- No force unwraps (`!`), no `try!`, no force casts (`as!`)
- No `String(format:)` -- use interpolation or formatted()
- Guard clauses for all validation; early returns over nested ifs
- Division safety: always check for zero before dividing
- Swift 6 strict concurrency compliance
- All public APIs require DocC documentation
- Zero C dependencies (Foundation + Darwin/Glibc only)

## Architecture

SwiftCLIKit is a two-layer terminal abstraction library:

**Layer 1 (Terminal):** v0.1.0-v0.2.0
- Terminal/: RawTerminal, TerminalSize, TerminalSettings, AlternateScreen, CursorControl
- Input/: Key, KeyReader, LineEditor, InputHistory, MouseEvent
- Rendering/: ANSICodes, Color, ColorNegotiation, ScreenBuffer, BoxDrawing, StatusArea
- Util/: UnicodeWidth, ANSIStringMetrics, HexColor

**Layer 2 (UI):** v0.3.0+
- Cell/: Cell, CellAttributes, CellBuffer
- Layout/: Rect, Layout, Frame
- Rendering/: DiffRenderer
- Widgets/: Table, List, Tree, Gauge, ProgressBar, Sparkline, BarChart, Tabs, Menu, Scrollbar, CalendarView, Block, Paragraph, CellStyle
- Framework/: App, Cmd, Subscription, EventStream, Event, FocusManager, Component

## Quality Gate

Run `quality-gate` before every commit. All checks must pass.

## References

- Full guidelines: `development-guidelines/README.md`
- Coding rules: `development-guidelines/00_CORE_RULES/01_CODING_RULES.md`
- TDD contract: `development-guidelines/00_CORE_RULES/09_TEST_DRIVEN_DEVELOPMENT.md`
- Session workflow: `development-guidelines/00_CORE_RULES/07_SESSION_WORKFLOW.md`
- Roadmap: `development-guidelines/02_IMPLEMENTATION_PLANS/UPCOMING/SwiftCLIKit_ROADMAP.md` (in iconquer repo)