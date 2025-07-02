# QuickSnipe

A modern, efficient clipboard manager for macOS with quick editing capabilities.

## Features

- 📋 **Clipboard History**: Automatically saves clipboard history
- ✏️ **Quick Editor**: Edit clipboard content before pasting
- 📌 **Pinned Items**: Pin frequently used items
- 🔍 **Search**: Quickly search through clipboard history
- ⌨️ **Global Hotkey**: Access with `⌃⌥M` from anywhere
- 🎨 **Modern UI**: Clean, native macOS interface

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later

## Setup

1. Install dependencies:
   ```bash
   brew install xcodegen swiftlint
   ```

2. Generate Xcode project:
   ```bash
   make create-project
   ```

3. Build and run:
   ```bash
   make run
   ```

## Development

### Build Commands

- `make build` - Build development version
- `make run` - Build and run
- `make build-release` - Build release version
- `make test` - Run tests
- `make lint` - Run SwiftLint
- `make clean` - Clean build artifacts

### Project Structure

```
QuickSnipe/
├── App/                 # Application entry point
├── Domain/              # Business logic and models
├── Data/               # Data persistence
├── Presentation/       # UI layer (SwiftUI)
├── Infrastructure/     # Platform services
└── Resources/          # Assets and localization
```

## Architecture

The project follows Clean Architecture principles with MVVM pattern:

- **Domain Layer**: Contains business logic, models, and use cases
- **Data Layer**: Handles data persistence and external data sources
- **Presentation Layer**: SwiftUI views and ViewModels
- **Infrastructure Layer**: Platform-specific services and utilities

## License

Copyright © 2025 QuickSnipe. All rights reserved.