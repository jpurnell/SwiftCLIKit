# SwiftCLIKit Guide

## Library Overview

SwiftCLIKit is a pure Swift terminal abstraction library. It provides raw mode
terminal access, keyboard input parsing (including full UTF-8 and ANSI escape
sequences), line editing with history, screen rendering primitives, and Unicode
display-width calculations -- all with zero C dependencies beyond the system
libc already linked by Swift.

### Design Philosophy

- **RAII safety.** `RawTerminal` enters raw mode in `init` and restores the
  original terminal state in `deinit`. You cannot forget to clean up.
- **Value types first.** `LineEditor`, `InputHistory`, `ScreenBuffer`,
  `TerminalSettings`, and `TerminalSize` are all structs. Mutating methods make
  state changes explicit at the call site.
- **Swift 6 strict concurrency.** Every public type is `Sendable`. The two
  reference types (`RawTerminal` and `StatusArea`) use `@unchecked Sendable`
  with documented justifications and lock-based synchronization.
- **No Foundation UI frameworks.** The library depends only on `Foundation` for
  `ProcessInfo`, `FileManager`, `JSONEncoder`/`JSONDecoder`, and
  `NSRegularExpression`. No AppKit, UIKit, or SwiftUI.

### Module Organization

```
Sources/SwiftCLIKit/
  Terminal/
    RawTerminal.swift        -- raw mode entry/exit, byte-level reads
    TerminalSettings.swift   -- color mode, render width, JSON persistence
    TerminalSize.swift       -- ioctl size query, SIGWINCH resize callbacks
  Input/
    Key.swift                -- Key enum (characters, arrows, ctrl-combos)
    KeyReader.swift          -- byte-to-Key parser (UTF-8, CSI sequences)
    LineEditor.swift         -- single-line editor with cursor movement
    InputHistory.swift       -- up/down history navigation with stash
  Rendering/
    ANSICodes.swift          -- escape constants (clear, cursor, SGR styles)
    BoxDrawing.swift         -- Unicode and ASCII box-drawing character sets
    ScreenBuffer.swift       -- frame builder (append, clear, render)
    StatusArea.swift         -- thread-safe scrolling message area
  Util/
    ANSIStringMetrics.swift  -- visible length, pad, truncate (ANSI-aware)
    UnicodeWidth.swift       -- East Asian Width + emoji display widths
    HexColor.swift           -- hex color string to nearest ANSI-8 color
```

### Roadmap

v0.1.0 is the foundation layer: raw mode, key reading, line editing, basic
rendering. Future versions will add 256-color and true-color support, mouse
event parsing, cell-based screen buffers, and scrollable regions.

---

## Quick Start: Raw Mode + Key Reading

A complete program that enters raw mode, reads keystrokes, and exits cleanly
on Ctrl-C:

```swift
import SwiftCLIKit

let terminal = RawTerminal()
let reader = KeyReader(terminal: terminal)

print("Press keys (Ctrl-C to exit):")

while let key = reader.readKey() {
    switch key {
    case .ctrlC:
        print("\nGoodbye!")
        exit(0)  // RawTerminal restores terminal in deinit
    case .character(let ch):
        print("You pressed: \(ch)")
    case .arrowUp:    print("Up!")
    case .arrowDown:  print("Down!")
    default:
        print("Key: \(key)")
    }
}
```

`RawTerminal` duplicates the file descriptor at init time and restores the
original termios settings when deallocated. If stdin is not a terminal (for
example, a pipe), raw mode is silently skipped but `readByte()` still works.

---

## Line Editing

`LineEditor` is a value-type single-line editor. Feed it keys from `KeyReader`
and it returns a `LineResult` telling you what happened. Pair it with
`InputHistory` for up/down arrow history navigation.

```swift
import SwiftCLIKit

let terminal = RawTerminal()
let reader = KeyReader(terminal: terminal)
var editor = LineEditor()
var history = InputHistory()

func redraw() {
    // Move to column 1, clear line, redraw prompt + text
    print("\r\u{001B}[K> \(editor.displayText)", terminator: "")
    // Position cursor accounting for prompt width
    let cursorCol = 3 + editor.cursorPosition  // "> " is 2 chars + 1-based
    print("\r\u{001B}[\(cursorCol)G", terminator: "")
    fflush(stdout)
}

redraw()

while let key = reader.readKey() {
    // History navigation
    if case .arrowUp = key {
        if let previous = history.navigateUp(current: editor.text) {
            editor = LineEditor(text: previous)
        }
        redraw()
        continue
    }
    if case .arrowDown = key {
        if let next = history.navigateDown() {
            editor = LineEditor(text: next)
        }
        redraw()
        continue
    }

    let result = editor.handleKey(key)
    switch result {
    case .completed(let line):
        print()  // newline after the entered text
        history.add(line)
        history.reset()
        // Process the line here...
        editor = LineEditor()  // reset for next input
    case .eof:
        print("\n[EOF]")
        exit(0)
    case .interrupt:
        print("\n[Interrupted]")
        exit(1)
    case .editing:
        break
    }
    redraw()
}
```

### LineEditor Key Bindings

| Key           | Action                          |
|---------------|---------------------------------|
| printable     | Insert character at cursor      |
| Backspace     | Delete character before cursor  |
| Delete        | Delete character at cursor      |
| Arrow Left    | Move cursor left                |
| Arrow Right   | Move cursor right               |
| Home / Ctrl-A | Move cursor to start of line    |
| End / Ctrl-E  | Move cursor to end of line      |
| Ctrl-K        | Kill text from cursor to end    |
| Ctrl-U        | Kill text from start to cursor  |
| Ctrl-W        | Delete word before cursor       |
| Ctrl-D        | Delete at cursor, or EOF if empty |
| Enter         | Submit line                     |
| Ctrl-C        | Interrupt                       |

### InputHistory

`InputHistory` stores up to `maxEntries` (default 100) unique consecutive
lines. Call `navigateUp(current:)` to stash the current input and walk
backward; call `navigateDown()` to walk forward. Call `reset()` after each
completed line to return to the end of history.

---

## Screen Rendering

`ScreenBuffer` builds a frame string that you print in one shot to avoid
flicker. Combine it with `BoxDrawing` for bordered panels.

```swift
import SwiftCLIKit

let size = TerminalSize.current()
let box = BoxDrawing.unicode
var buffer = ScreenBuffer(width: size.columns)

// Draw a box
buffer.appendLine(box.topBorder(" Status ", width: size.columns))
buffer.appendLine(
    box.vertical
    + ANSIStringMetrics.padVisible(" All systems operational", to: size.columns - 2)
    + box.vertical
)
buffer.appendLine(box.bottomBorder(width: size.columns))

// Render: clears screen, homes cursor, prints content
print(buffer.frame, terminator: "")
fflush(stdout)
```

`BoxDrawing` provides two built-in character sets:

- `BoxDrawing.unicode` -- single-line Unicode box characters (U+250x).
- `BoxDrawing.ascii` -- plain `+`, `-`, `|` for environments without Unicode.

The `topBorder(_:width:)` method embeds a header string into the top edge,
truncating it with `ANSIStringMetrics` if it exceeds the available width.

---

## Terminal Settings

`TerminalSettings` provides persistent per-application configuration stored at
`$XDG_CONFIG_HOME/<appName>/terminal.json` (or `~/.config/<appName>/terminal.json`).

```swift
import SwiftCLIKit

// Load saved settings (returns defaults if no file exists)
var settings = TerminalSettings.load(appName: "myapp")

// Resolve whether to use color based on mode + environment
let useColor = settings.resolveColor()

// Modify and save
settings.colorMode = .always
settings.asciiOnly = true
try settings.save(appName: "myapp")
```

### Color Resolution

`resolveColor()` checks, in order:

1. `.never` -- always returns false.
2. `.always` -- always returns true.
3. `.auto` -- returns false if `NO_COLOR` is set in the environment; otherwise
   returns true if stdout is a terminal (via `isatty`).

You can pass `isattyOverride: true/false` for testing.

---

## Terminal Size and Resize

`TerminalSize.current()` queries the terminal dimensions via `ioctl`. It
returns an 80x24 fallback if the query fails (for example, when running in a
pipe).

```swift
let size = TerminalSize.current()
print("Terminal is \(size.columns) x \(size.rows)")
```

To react to window resizes, register a callback that fires on `SIGWINCH`:

```swift
// Keep the token alive as long as you want resize notifications
let token = TerminalSize.onResize { newSize in
    print("Resized to \(newSize.columns)x\(newSize.rows)")
}

// When token is deallocated, the callback is automatically unregistered
```

---

## Unicode Width

Terminal columns and `String.count` are different things. A CJK ideograph
occupies 2 columns. An emoji with a variation selector occupies 2 columns. A
combining accent mark occupies 0 columns. `UnicodeWidth` handles all of these.

```swift
import SwiftCLIKit

// Single characters
UnicodeWidth.width(of: Character("A"))    // 1
UnicodeWidth.width(of: Character("\u{4E16}"))  // 2 (CJK: "world")
UnicodeWidth.width(of: Character("\u{0301}"))  // 0 (combining acute accent)

// Full strings
UnicodeWidth.displayWidth("Hello")         // 5
UnicodeWidth.displayWidth("Hello\u{4E16}") // 7
```

### ANSI-Aware String Metrics

`ANSIStringMetrics` strips ANSI escape sequences before measuring, so colored
text reports its true visible width:

```swift
let styled = ANSICodes.bold + "Error" + ANSICodes.reset
ANSIStringMetrics.visibleLength(styled)  // 5, not 13

// Pad to a column width (adds spaces, ignores escapes in measurement)
ANSIStringMetrics.padVisible(styled, to: 20)

// Truncate to a column width (preserves ANSI state, appends reset if needed)
ANSIStringMetrics.truncateVisible(longStyledString, to: 40)
```

---

## Status Area

`StatusArea` is a thread-safe scrolling message buffer. It keeps the most
recent N messages (default 5) and renders them as truncated, optionally
dimmed lines.

```swift
import SwiftCLIKit

let status = StatusArea(maxMessages: 3)

status.push("Connected to server")
status.push("Loading map data...")
status.push("Ready")

let size = TerminalSize.current()
let lines = status.render(width: size.columns, colorize: true)
for line in lines {
    print(line)
}

// Clear all messages
status.clear()
```

`StatusArea` uses `NSLock` internally, so you can call `push` from any thread
or Swift concurrency context.

---

## Hex Color Mapping

`HexColor` maps CSS-style hex color strings to the nearest ANSI 8-color value.
This is useful when your data model stores colors as hex but your terminal only
supports basic ANSI colors.

```swift
import SwiftCLIKit

let color = HexColor.toANSI8("#FF5733")  // .red
let escape = HexColor.toANSIEscape("#336699")  // ANSI blue foreground escape

print(escape + "Blue text" + ANSICodes.reset)
```

---

## Platform Support

| Platform | Raw mode | Key reading | ioctl size | SIGWINCH |
|----------|----------|-------------|------------|----------|
| macOS    | Yes      | Yes         | Yes        | Yes      |
| Linux    | Yes      | Yes         | Yes        | Yes      |
| Other    | No-op    | Pipe only   | Fallback   | No-op    |

On unsupported platforms, `RawTerminal` skips raw mode but `readByte()` still
works on pipe input. `TerminalSize.current()` returns the 80x24 fallback.
Resize callbacks are not registered.

---

## Integration Pattern

To use SwiftCLIKit in another Swift package, add it as a local or remote
dependency:

```swift
// Package.swift
let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        // Local (sibling directory):
        .package(path: "../SwiftCLIKit"),
        // Or remote:
        // .package(url: "https://github.com/you/SwiftCLIKit.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: ["SwiftCLIKit"]
        ),
    ]
)
```

Then `import SwiftCLIKit` in any source file to access all public types.
