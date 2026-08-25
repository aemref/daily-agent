# Daily Agent

A small native macOS menu bar companion for following a 365-day AI/LLM engineering and AWS roadmap. The in-app companion is called **Codex Pet**.

## Open the app

After building, open Finder and double-click:

```text
build/Codex Pet.app
```

The app does not appear in the Dock. Look for the sparkle icon in the macOS menu bar at the top-right of the screen. Click it to open today's tasks, then choose **Kenara sabitle** to keep the floating pet on the screen edge.

## MVP features

- Native SwiftUI `MenuBarExtra`
- Dockless agent app (`LSUIElement`)
- Optional floating edge panel powered by `NSPanel`
- Compact pet and expanded daily dashboard
- Static 12-month roadmap with three generated tasks per day
- Local JSON persistence for task completion and streak data
- Nine portfolio repositories mapped across four milestones

## Requirements

- macOS 14 or newer
- Xcode 16 or newer / Swift 6

## Run in development

```bash
swift run CodexPet
```

## Build the app bundle

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "build/Codex Pet.app"
```

If macOS blocks the first launch, right-click **Codex Pet.app**, choose **Open**, and confirm once.

The app stores local progress at:

```text
~/Library/Application Support/CodexRoadmapPet/state.json
```

## Next milestones

- Add/edit/reschedule tasks
- Local notifications
- Launch at login
- GitHub contribution verification
- Weekly review and export
- Optional AI task breakdown
