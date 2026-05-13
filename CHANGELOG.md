# Changelog

All notable changes to SwiftCLIKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Inline gauge and sparkline widgets
- Formatting utilities (elapsed, duration, bytes, time, rate)
- Accessibility `reduceMotion` support in animations

### Fixed
- DiffRenderer color bleed after render
- Path traversal hardening in SnapshotTesting, SessionPlayer, SessionRecorder
- Floating-point safety in PerfTracker FPS calculation

## [1.14.0] - 2025-05-12

### Added
- Backtab (Shift-Tab) key support (CSI Z)

### Fixed
- Color.default uses .defaultColor case with SGR 39/49

## [1.12.0] - 2025-05-08

### Added
- Embedded SSH server module (SwiftCLIKitSSH)

## [1.0.0] - 2025-04-10

### Added
- Two-layer terminal abstraction (Terminal + UI)
- Cell-based rendering with CellBuffer and DiffRenderer
- Widget library: Table, List, Tree, Gauge, ProgressBar, Sparkline, BarChart, Tabs, Menu, Scrollbar, CalendarView, Block, Paragraph
- Layout system with Rect, Layout, Frame
- App/Cmd/Subscription framework with EventStream
- Input handling: Key, KeyReader, LineEditor, InputHistory, MouseEvent
- Alternate screen, cursor control, raw terminal mode
- ANSI color negotiation (truecolor, 256-color, 16-color)
- Unicode width support and ANSI string metrics
- FocusManager and Component protocol
- Snapshot testing support
- Session recording and playback
- Performance tracking
- Accessibility labels, roles, and announcements
