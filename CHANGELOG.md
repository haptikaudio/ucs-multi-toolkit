# Changelog

All notable changes to UCS Multi Toolkit are documented here.

## [1.0.2] — 2026-06-07

### Changed

- Replaced simplified category list with full **UCS v8.2.1** data (82 categories, 753 subcategories)
- Updated smart-suggest keyword hints and compound matchers for the official CatShort codes

## [1.0.1] — 2026-06-07

### Fixed

- ReaPack package name now includes `.lua` so the script registers in REAPER's Action List after install

## [1.0.0] — 2026-06-07

Initial public release.

### Added

- Dockable UCS workflow UI (space, glue, normalize, rename, render)
- Built-in workflow presets including **Clean Slate** as default
- Smart field suggest with UCS tail parsing and keyword hints
- Pre-flight confirmation modal with keyboard support (Enter / Esc)
- REAPER render with `$item` output and optional **region** render
- Post-render import to track below source item
- Workflow preset save/load with optional render preset sync
- Horizontal scroll in text inputs and clipped preview bar
- Haptik Audio branding (logo + footer)
- Settings persistence via ExtState

### Fixed

- Multi-word UCS subcategories normalized to underscore format in filenames
- Pre-flight modal button visibility in docked mode
- Compact pre-flight dialog sizing for smaller displays
