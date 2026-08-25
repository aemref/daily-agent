# Daily Agent

A native macOS menu bar assistant that turns a PDF or pasted roadmap into a one-year daily plan with OpenAI. The in-app companion is called **Codex Pet**.

## Start here: add your own OpenAI API key

This public repository does **not** include an API key. Create your local `.env` file before building:

```bash
cp .env.example .env
```

Open `.env` and add your own key:

```dotenv
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-5.6-luna
```

Never commit `.env`. It is already ignored by Git.

Daily Agent uses the OpenAI Responses API with strict Structured Outputs to create a validated weekly roadmap. You can change the model through `OPENAI_MODEL` as long as it supports Structured Outputs.

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
- Animated pet with idle movement, blinking, and progress reactions
- Compact pet and expanded daily dashboard
- PDF import with native PDFKit text extraction
- Paste-in roadmap or goal text
- Clickable Monday-Sunday workday selection
- Fixed one-year plan scheduled only on selected weekdays
- OpenAI Responses API integration using strict JSON Schema output
- Prompt-injection boundary that treats imported documents as untrusted data
- AI roadmap preview before activation
- Selected-weekday weekly-to-daily scheduling
- Local JSON persistence for task completion and streak data
- No API keys or imported PDFs stored in the repository

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

When running the app from the repository, it reads `.env` from the project root. If you move the built app somewhere else, you can place a private `.env` file at:

```text
~/Library/Application Support/DailyAgent/.env
```

## How planning works

```text
PDF or pasted text
        ↓
Local PDFKit extraction
        ↓
OpenAI Responses API + strict JSON Schema
        ↓
Validated weekly roadmap preview
        ↓
Local selected-weekday daily scheduler
        ↓
Menu bar tasks and floating pet
```

The content inside an imported document is treated as untrusted reference data, not as instructions. Users are shown that extracted text is sent to the OpenAI API when they generate a roadmap.

## OpenAI API references

- [Responses API](https://developers.openai.com/api/reference/cli/resources/responses/methods/create)
- [Models](https://developers.openai.com/api/docs/models)

## Next milestones

- Local notifications
- Launch at login
- GitHub contribution verification
- Weekly review and export
- Edit and reschedule generated tasks
- Adaptive replanning for missed days
