# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-05-16

### Added
- Batch task creation from multi-line paste — paste 2–20 lines into the title field and choose to create one task per line; URL lines are resolved to their page title automatically, and a failed line falls back to the raw URL without aborting the batch.
- Windows desktop build — QuickTask now ships as a Windows desktop app alongside the Android APK, with a compact portrait window and an enforced minimum size.
- GitHub Actions CI and release workflows — every push to main and every PR is automatically analyzed, formatted, and tested; pushing a version tag builds both the APK and the Windows ZIP and publishes them as a GitHub Release.

## [0.2.0] - 2026-04-20

### Added
- Favorite projects in the project picker — star a project to pin it to the top; favorites section is shown above Recent and All Projects.
