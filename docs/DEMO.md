# ChartLens Demo App

## Running

```sh
xcodebuild -project ChartLens/ChartLens.xcodeproj -scheme DemoApp -configuration Debug -destination 'platform=macOS' build
xed ChartLens/ChartLens.xcodeproj
```

The DemoApp is a macOS app inside the ChartLens Xcode project. It contains interactive demonstrations of every ChartLens feature.

## Demos

| Demo | File | Section | Description |
|------|------|---------|-------------|
| BasicCharts | `BasicChartsDemo.swift` | Chart Types | Line, area, dot, step, multi-series, custom axis |
| Candlestick | `CandlestickDemo.swift` | Chart Types | OHLC K-line chart |
| Gaussian | `GaussianDemo.swift` | Chart Types | WiFi spectrum: single/multi-AP Gaussian bell curves |
| Pie & Donut | `SectorDemo.swift` | Chart Types | Basic pie, donut, polar hover/tap, and empty data |
| Interpolation | `InterpolationDemo.swift` | Interpolation | Linear, Catmull-Rom, clamped cubic, stepped, gaussian |
| SplineOvershoot | `SplineOvershootDemo.swift` | Interpolation | Catmull-Rom vs clamped cubic overshoot comparison |
| Interactions | `InteractionsDemo.swift` | Interaction | Hover, tap, and zoom gesture callbacks |
| Crosshair | `CrosshairDemo.swift` | Interaction | Crosshair overlay with hover tracking |
| DetailOverview | `DetailOverviewDemo.swift` | Composition | Linked overview+detail chart pair |
| Overlay | `OverlayDemo.swift` | Composition | Custom overlay injection (tooltip, labels, threshold) |

## Architecture

```
DemoApp
├── DemoPage enum (sidebar navigation with sections)
├── DemoCard (reusable card wrapper)
└── Sources/DemoApp/
    ├── BasicChartsDemo
    ├── CandlestickDemo
    ├── GaussianDemo
    ├── SectorDemo
    ├── CrosshairDemo
    ├── DetailOverviewDemo
    ├── InteractionsDemo
    ├── InterpolationDemo
    ├── OverlayDemo
    └── SplineOvershootDemo
```

Each demo is a self-contained SwiftUI View. `DemoApp.swift` defines the `NavigationSplitView` shell with a sectioned sidebar (`Chart Types`, `Interpolation`, `Interaction`, `Composition`).
