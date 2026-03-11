# ReadMini macOS Specification

## 1. Product Scope

ReadMini macOS is a desktop RSS reader for macOS.

The current release is an MVP focused on subscription management, cached article browsing, and readable article detail pages. It is explicitly reading-first and does not yet include podcast playback or advanced feed management.

## 2. Supported Content

### 2.1 Feed Types

- RSS 2.0
- Atom

### 2.2 Stored Article Fields

Each cached article may include:

- title
- link
- feed title
- summary HTML
- content HTML
- plain-text summary
- plain-text content
- author
- published timestamp
- first image URL

## 3. Functional Requirements

### 3.1 Subscription Management

- The user can add a subscription by entering a feed URL manually.
- The user can import curated default feeds from a dedicated sheet.
- The default feed sheet must support selecting a subset of feeds before import.
- The user can remove an existing subscription.
- Removing a subscription must also remove cached articles for that subscription.

### 3.2 Feed Refresh

- The app can refresh all subscriptions.
- The app can refresh the currently selected subscription.
- Adding a subscription must trigger an initial fetch.
- Failed refresh for one subscription must not corrupt cached content for others.

### 3.3 Article List

- The main window must use a desktop split layout with:
  - subscription sidebar
  - article list
  - article detail
- The article list must show:
  - title
  - source title
  - summary preview
  - publish time when available
  - thumbnail when a meaningful first image exists

### 3.4 Article Detail

- Opening an article must show:
  - first image when available
  - title
  - source title
  - author when available
  - publish time when available
  - article content
- Article text must support selection and copy.
- The detail view must offer:
  - open in browser
  - copy link

### 3.5 Settings

- The app must support theme mode:
  - system
  - light
  - dark
- The app must support reading font size:
  - small
  - medium
  - large
- Settings must be reachable from the top-right toolbar menu.
- Settings must apply immediately to the reading UI.

## 4. Persistence Requirements

- Subscriptions, articles, and settings must be stored locally with `SwiftData`.
- Subscriptions must be unique by feed URL.
- Articles must be deduplicated by:
  - `subscriptionID + link` when link exists
  - otherwise `subscriptionID + title + publishedAt`

## 5. Parsing Requirements

- Feed parsing must tolerate missing optional fields.
- If `content` is unavailable, the app must fall back to `summary`.
- If both `summary` and `content` are HTML, the app may store both and also derive plain-text fields for faster UI rendering.
- The parser must attempt to extract the first image URL from article HTML content.

## 6. Non-Functional Requirements

### 6.1 Platform

- Minimum macOS version: 14.0
- Native `SwiftUI` app

### 6.2 Performance

- Already-cached content should remain readable offline.
- Scrolling and pane resizing should avoid repeated HTML-to-attributed-string conversion during every redraw.
- The article detail pane should use the available width without leaving unnecessary fixed-width whitespace.

### 6.3 Error Handling

- Invalid subscription URLs must show a user-facing error.
- Invalid or unsupported feeds must show a user-facing error.
- Importing already-added default feeds should be treated as a non-fatal no-op.

## 7. Known Limits

- No podcast playback
- No full-text extraction from the source web page
- No search
- No read/unread state
- No sync
- No feed grouping or tagging
