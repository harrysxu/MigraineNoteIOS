# Repository Guidelines

## Project Structure & Module Organization

This repository contains an iOS migraine tracking app, public pages, and documentation.

- `migraine_note/migraine_note.xcodeproj` is the Xcode project.
- `migraine_note/migraine_note/` contains Swift app code, organized by role: `Models/`, `Views/`, `ViewModels/`, `Services/`, `Extensions/`, and `Protocols/`.
- `migraine_note/migraine_noteTests/` contains unit tests and shared helpers in `TestHelpers.swift`.
- `migraine_note/migraine_noteUITests/` contains XCTest UI flows.
- `docs/` contains product, architecture, App Store, design-system, and screenshot assets.
- `pages/` contains static support, privacy, terms, and landing pages.

## Build, Test, and Development Commands

Run commands from the repository root unless noted.

- `open migraine_note/migraine_note.xcodeproj` opens the app in Xcode.
- `xcodebuild -project migraine_note/migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' build` builds the app for Simulator.
- `xcodebuild -project migraine_note/migraine_note.xcodeproj -scheme migraine_note -destination 'platform=iOS Simulator,name=iPhone 16' test` runs unit and UI tests when a matching simulator is available.

If the simulator name differs, list options with `xcrun simctl list devices available`.

## Coding Style & Naming Conventions

Use Swift 5 conventions and match nearby files.

- Use 4-space indentation and avoid trailing whitespace.
- Name Swift types in `UpperCamelCase`, functions/properties in `lowerCamelCase`, and test files as `<Subject>Tests.swift`.
- Keep SwiftUI views in `Views/<Feature>/`, view models in `ViewModels/`, domain data in `Models/`, and app services in `Services/`.
- Prefer small, focused types and dependency injection for testable services and view models.
- No project-wide SwiftLint config is present; rely on Xcode formatting and existing style.

## Testing Guidelines

Tests use XCTest.

- Add unit tests in `migraine_note/migraine_noteTests/` for models, services, view models, exporters, and extensions.
- Add UI flows in `migraine_note/migraine_noteUITests/` when behavior depends on navigation or user interaction.
- Name test methods descriptively, for example `testMedicationLogCalculatesDailyUsage()`.
- Use `TestHelpers.swift` for shared fixtures instead of duplicating setup.

## Commit & Pull Request Guidelines

Recent history uses very short messages such as `add`; improve on that with concise, imperative summaries like `Add medication reminder tests`.

Pull requests should include:

- A short description of user-facing or technical changes.
- Test results, including the exact `xcodebuild` command or Xcode scheme used.
- Linked issues or docs when applicable.
- Screenshots or recordings for visible UI changes, especially under `Views/` or `pages/`.

## Agent-Specific Instructions

Keep edits focused and avoid committing generated Xcode user data such as `xcuserdata/`, `.xcuserstate`, `DerivedData/`, or `.DS_Store`. Do not change app entitlements, bundle identifiers, or deployment targets unless the task explicitly requires it.
