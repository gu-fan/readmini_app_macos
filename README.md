# ReadMini macOS

ReadMini macOS is a native macOS RSS and Atom reader built with `SwiftUI` and `SwiftData`.

The current version focuses on a clean desktop reading workflow:

- add subscriptions manually
- import curated default feeds
- refresh one subscription or all subscriptions
- cache subscriptions and articles locally
- browse articles in a three-column desktop layout
- read article content with selectable text
- open article links in the browser
- copy article links
- switch theme mode
- adjust reading font size

## Tech Stack

- Swift 6
- SwiftUI
- SwiftData
- URLSession
- Foundation XML parsing

## Requirements

- macOS 14.0+
- Xcode 16.2+ or Swift 6 toolchain

## Project Structure

```text
Sources/ReadMiniMacOS
├── App           # App entrypoint and window setup
├── Application   # Observable app store and UI actions
├── Data          # Feed fetch, parse, persistence, repository
├── Domain        # Models, settings, default feed catalog
├── Support       # HTML helpers
└── UI            # SwiftUI views

Tests/ReadMiniMacOSTests
└── Parser and repository tests
```

## Run

Build:

```bash
swift build
```

Run:

```bash
swift run
```

Open in Xcode:

```bash
open Package.swift
```

## Test

```bash
swift test
```

## Package

Build a release `.app` bundle and zip archive:

```bash
./scripts/package_app.sh
```

Artifacts:

- `dist/ReadMiniMacOS.app`
- `dist/ReadMiniMacOS.zip`

## Current Product Shape

ReadMini macOS is intentionally narrow in scope.

It is a local-first desktop reader, not a full feed management suite. The current implementation does not include:

- podcast playback
- web-page full-text extraction
- sync
- search
- read state
- favorites or bookmarks

## Notes

- Feed parsing supports both RSS 2.0 and Atom.
- Article content is rendered from feed-provided summary or content fields.
- HTML-to-text and article rendering are cached in memory where practical to keep scrolling and resizing responsive.
- Default feed import supports multi-select import instead of all-or-nothing import.
