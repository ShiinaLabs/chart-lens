# AGENTS.md

This file provides guidance to AI coding agents (Codex, Copilot, Cursor, Windsurf, Claude Code, and others) when working in this repository.

## Docs Directory

All detailed documentation lives under `docs/`. When adding or updating documentation, always place it there. Never create standalone `.md` files at the repo root (except this file, `CLAUDE.md`, and `README.md`).

| File | Purpose |
|------|---------|
| `docs/ARCHITECTURE.md` | Architecture, data flow, key patterns, design conventions |
| `docs/API.md` | Complete public API reference for all ChartLens types and protocols |
| `docs/DEMO.md` | DemoApp structure, running instructions, demo catalog |
| `docs/TESTING.md` | Test architecture, running tests, adding new test files |

## Build & Test

```sh
# SPM
cd ChartLens && swift build              # build
cd ChartLens && swift test               # test

# DemoApp (Xcode project)
xcodebuild -project ChartLens/ChartLens.xcodeproj -scheme DemoApp -configuration Debug -destination 'platform=macOS' build
xcodebuild -project ChartLens/ChartLens.xcodeproj -scheme ChartLensTests -configuration Debug -destination 'platform=macOS' test
xed ChartLens/ChartLens.xcodeproj
```

## Key Facts

- macOS 14+, iOS 17+, Swift 6.0, SwiftUI + Canvas rendering
- Tests use Swift Testing (`@Test`, `#expect()`) with `import ChartLens`
- Protocol-driven architecture: `ChartPointProtocol` → `ChartSeriesRenderer<Point>` → `ChartSeries<Point>: ChartSeriesProtocol`
- `Chart<Overlay>` stores `[any ChartSeriesProtocol]` for mixed chart types
- Overlays (crosshairs, tooltips, etc.) are injected via `@ViewBuilder overlay: (ChartGeometry, [any ChartSeriesProtocol]) -> Overlay`
- `SectorChart` is a separate polar family using `SectorDatum`, `SectorLayout`, `SectorGeometry`, and `SectorInteraction`; do not force sector data into the Cartesian point/series protocols
- All public types conform to `Sendable` for Swift 6 strict concurrency
- `ChartInteraction` callbacks are `@MainActor`-bound

## Rules

- Never commit without explicit user instruction
- Never push unless asked
- **English is the primary language.** All docs, code comments, and commit messages must be in English.
- **All `.md` docs go in `docs/`** — this AGENTS.md, CLAUDE.md, and README are the only exceptions
- When creating new docs, update the table in this file
