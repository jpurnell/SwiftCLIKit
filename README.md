# SwiftCLIKit

Pure Swift terminal abstraction library -- raw mode, input parsing, line editing, and rendering primitives with zero C dependencies.

## Requirements

- Swift 6.0+
- macOS 15+ or Linux

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../SwiftCLIKit"),
]
```

## Quick Start

```swift
import SwiftCLIKit

let terminal = RawTerminal()
let reader = KeyReader(terminal: terminal)

while let key = reader.readKey() {
    if case .ctrlC = key { break }
    print("Key: \(key)")
}
```

## Documentation

See [SwiftCLIKitGuide.md](SwiftCLIKitGuide.md) for full documentation.

## License

MIT
