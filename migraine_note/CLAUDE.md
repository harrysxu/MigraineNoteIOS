# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS application called "头痛管家" (Migraine Manager) - a migraine tracking and health management app built with SwiftUI and SwiftData. It supports iOS 17.6+ and uses CloudKit for data synchronization.

## Build Commands

The project uses Xcode's build system. Run commands from the project root (`/Users/long/OpenSource/migraine_note_ios/migraine_note/`):

```bash
# Build the project
xcodebuild -project migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests
xcodebuild -project migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a specific test class
xcodebuild -project migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:migraine_noteTests/HomeViewModelTests test

# Run a specific test method
xcodebuild -project migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:migraine_noteTests/HomeViewModelTests/testStreakDays_NoAttacks_ZeroDays test
```

## Architecture Overview

### Data Layer (SwiftData)

The app uses SwiftData for persistence with CloudKit sync support. Key models:

- **AttackRecord** - Core migraine attack records with pain intensity (0-10 VAS), location, quality, aura, symptoms, triggers, and medication logs
- **CustomLabelConfig** - Configurable labels for symptoms, triggers, pain qualities, interventions, and auras. Supports both default and user-defined labels with visibility control
- **HealthEvent** - Non-attack health events: daily medication, TCM treatments, surgeries
- **Medication/MedicationLog** - Drug inventory and usage tracking
- **WeatherSnapshot** - Weather data associated with attack records

Key architectural decisions:
- Records store `displayName` strings directly, not foreign keys to labels. This decouples historical records from label modifications.
- Relationships use `*Data` suffix (e.g., `symptomsData`) with computed properties for CloudKit compatibility (relationships must be optional)
- Label deduplication runs after iCloud sync to handle multi-device default label creation
- **Localization Strategy**: Labels are initialized once at first launch based on system language. Dynamic language switching is not supported for labels (YAGNI principle - < 1% of users need this). See `docs/国际化简化说明.md` for details.

### View Architecture

- **MainTabView** - Root view with 4 tabs: Home, Records (AttackList), Analytics (premium-gated), Profile
- **SimplifiedRecordingView** - Single-page recording form using collapsible sections instead of step-by-step flow
- Views use `@Query` for label fetching and `@State` ViewModels for business logic
- `LazyView` wrapper delays tab view initialization until first access

### ViewModels

ViewModels use the `@Observable` macro (iOS 17+):

- **HomeViewModel** - Streak calculation, ongoing attack detection, timeline merging, monthly stats, weather integration
- **RecordingViewModel** - Attack recording/editing with weather auto-capture
- **AttackListViewModel** - List filtering, search, batch operations
- **CalendarViewModel** - Calendar view with attack/event dots

### Services

- **LabelManager** - Singleton managing default label initialization and custom label CRUD. Handles iCloud deduplication.
- **AnalyticsEngine** - Comprehensive analytics: trigger frequency, circadian patterns, medication usage, TCM stats. Uses `BatchAnalyticsResult` for efficient batch computation.
- **WeatherManager** - Location-based weather fetching with permission handling
- **MOHDetector** - Medication Overuse Headache risk detection
- **SyncSettingsManager** - iCloud sync toggle (affects ModelContainer configuration)

### Design System

- **ThemeManager** - Light/Dark/System theme persistence via `@AppStorage`
- **Colors.swift** - Semantic color definitions (e.g., `Color.accentPrimary`)
- **Typography.swift** - Text style extensions
- **Components/** - Reusable UI: `SelectableChip`, `CollapsibleSection`, `CircularSlider`, `HeadMapView`

## Testing

Tests are in `migraine_noteTests/` using XCTest with SwiftData in-memory containers:

```swift
// Use TestHelpers.swift utilities:
let context = try! makeTestModelContext()  // Fresh in-memory context per test
createAttack(in: context, painIntensity: 5)  // Helper to create test data
```

Testing patterns:
- Each test gets a fresh `ModelContext` via `makeTestModelContext()`
- Use `createAttack()`, `createMedication()`, `createHealthEvent()` helpers for test data
- Date helpers: `dateAgo(days:)`, `makeDate(year:month:day:)`

## Key Files Reference

| Purpose | Location |
|---------|----------|
| App Entry | `migraine_note/migraine_noteApp.swift` |
| Main Tab | `migraine_note/Views/MainTabView.swift` |
| Recording Form | `migraine_note/Views/Recording/SimplifiedRecordingView.swift` |
| Core Model | `migraine_note/Models/AttackRecord.swift` |
| Label Management | `migraine_note/Services/LabelManager.swift` |
| Analytics | `migraine_note/Services/AnalyticsEngine.swift` |
| Test Helpers | `migraine_noteTests/TestHelpers.swift` |

## Entitlements

The app uses these capabilities (see `migraine_note.entitlements`):
- CloudKit (iCloud sync)
- WeatherKit
- HealthKit (menstrual cycle correlation)
- Push notifications

## Localization

The app is Chinese-language focused with locale set to `zh_CN` in `migraine_noteApp.swift`. Enum rawValues and user-facing strings use Chinese.
