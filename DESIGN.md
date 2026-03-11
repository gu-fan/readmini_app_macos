# ReadMini macOS Design Notes

## Product Intent

ReadMini macOS is a desktop reading space for RSS, not a browser shell and not a power-user dashboard.

The design goal is to keep subscription management close at hand while letting article reading dominate the experience.

## Core Principles

### 1. Reading First

The detail pane carries the most visual weight.

Important consequences:

- the article title should be prominent
- metadata should stay secondary
- the reading column should breathe, but not waste available desktop width
- article actions should stay lightweight

### 2. Native Desktop Structure

macOS users expect resizable panes, persistent sidebars, and menu-driven secondary actions.

That leads to:

- `NavigationSplitView` as the primary container
- subscription list on the left
- article list in the middle
- article detail on the right
- settings reachable from a toolbar menu instead of only from the app menu

### 3. Calm Over Dense

ReadMini should feel closer to a quiet reading app than a control-heavy feed manager.

Design choices:

- soft spacing
- modest metadata
- limited toolbar actions
- no dense table layout in v1

### 4. Responsive Enough For Desktop

Desktop resizing is continuous, so rendering cost matters more than on mobile.

Current implementation choices:

- article summaries are converted to plain text before rendering rows
- article detail content is cached as attributed text per article and font size
- the detail column no longer uses a narrow fixed-width cap that leaves obvious dead space on wider windows

## Screen Intent

### Main Window

The main window handles the full reading workflow:

- choose a feed
- scan article headlines
- open and read an article
- refresh when needed

The toolbar exposes only the actions that belong at app-shell level:

- add subscription
- import default feeds
- refresh
- open settings from the top-right overflow menu

### Default Feed Import

The default feed sheet is intentionally batch-oriented, but not forced-batch.

It supports:

- select all
- clear all
- selective import
- explicit close button

This keeps onboarding fast while avoiding the frustration of importing every feed.

### Settings

Settings currently stay narrow and practical:

- theme mode
- reading font size

They are presented in-app as a sheet because users often want immediate feedback while looking at the reader window.

## Visual Direction

- dark and light themes should both feel editorial rather than dashboard-like
- typography should prioritize readability over stylization
- image thumbnails should help scanning, not overpower text
- details should stay visually stable during refresh and selection changes

## Future Design Opportunities

- remembered split-view widths
- subscription search
- read-state styling
- richer article typography
- keyboard shortcuts for feed and article navigation
