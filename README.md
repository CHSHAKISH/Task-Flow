# Task Flow

A polished task management Flutter app built as a **Track B (Mobile Specialist)** submission for the Flodo AI Take-Home Assignment.

---

## Screenshots

> Run the app locally to experience it live! The UI features smooth animations, a premium design system, and reactive state management.

---

## Setup Instructions

### Prerequisites
- Flutter SDK 3.11.0 or later
- Dart SDK 3.0.0 or later
- Android Studio / Xcode (for device emulation)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/CHSHAKISH/Task-Flow.git
cd task_flow

# 2. Install dependencies
flutter pub get

# 3. Generate Isar database schemas (if .g.dart files aren't present)
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Supported Platforms
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Web

---

## Track

**Track B – Mobile Specialist**

Focus: Deep Flutter/Dart expertise, local database, state management, and premium UI/UX.

---

## Stretch Goal

**Debounced Autocomplete Search with Text Highlighting**

- Search queries are debounced at **300ms** using a custom `Debouncer` utility
- Matching substrings in both **title** and **description** are highlighted in amber/yellow using a custom `HighlightedText` widget
- Combined with status filter chips for compound filtering

---

## Architecture

| Layer | Technology | Purpose |
|---|---|---|
| UI | Flutter + Material 3 | Screens, widgets, animations |
| State | Riverpod 2 | Reactive providers, search/filter state |
| Repository | `TaskRepository` | Abstraction over Isar |
| Database | Isar 3 | Physical persistence across restarts |
| Fonts | Google Fonts (Inter) | Premium typography |

### File Structure

```
lib/
├── main.dart                    # Entry point (~30 lines)
├── models/
│   ├── task.dart                # Isar @collection with @ignore guards
│   └── task_draft.dart          # Draft model with Isar annotations
├── repositories/
│   └── task_repository.dart     # Full Isar CRUD + draft operations
├── providers/
│   └── task_provider.dart       # Riverpod FutureProvider + StateProviders
├── screens/
│   └── task_list_screen.dart    # Main screen (ConsumerStatefulWidget)
├── widgets/
│   ├── task_card.dart           # Animated card with fade-in + HighlightedText
│   ├── task_form_dialog.dart    # Create/Edit dialog with draft auto-save
│   ├── search_filter_bar.dart   # 300ms debounced search + styled filter chips
│   └── highlighted_text.dart   # RichText span-based text highlighter
├── theme/
│   └── app_theme.dart           # Complete Material 3 design system
└── utils/
    └── debouncer.dart           # Reusable debounce timer wrapper
```

---

## Core Features

### ✅ CRUD Operations
- Create, Read, Update, Delete tasks
- All Create/Update operations simulate a **2-second delay** with a visible loading state
- The Save button is disabled during the operation to prevent double-tap

### ✅ Task Data Model
Each task has exactly the required 4 fields:
1. **Title** (String)
2. **Description** (String)
3. **Due Date** (DateTime)
4. **Status** (Enum: To Do / In Progress / Done)
5. **Blocked By** (Optional: dropdown to select another task)

### ✅ Blocked Tasks
- Tasks blocked by an incomplete task are visually greyed out (AnimatedOpacity)
- A lock icon and "Blocked by [Task Name]" label appears in the footer
- Blocked tasks cannot be tapped (editing is disabled)
- As soon as the blocker task is marked Done, the blocked task becomes active

### ✅ Search & Filter
- Search by title or description using the search bar (debounced 300ms)
- Filter by status using the color-coded chip row
- Search and filter can be combined

### ✅ Draft Persistence
- When the user minimizes the app while typing a new task, the draft is automatically saved to Isar (physical DB)
- On next launch, a "Unsaved Draft" dialog appears with the draft content preview
- User can **Resume** (pre-fills the form) or **Discard** the draft
- Drafts older than 24 hours are silently discarded

---

## Design System

- **Color Palette**: Deep Indigo (#5C6BC0) primary, with semantic status colors
- **Typography**: [Inter](https://fonts.google.com/specimen/Inter) via Google Fonts
- **Cards**: Borderless elevation-0 cards with a subtle grey border and 16dp radius
- **Animations**: Fade-in on card mount, AnimatedOpacity for blocked state, AnimatedContainer for filter chip selections, AnimatedSwitcher for save button loading state
- **Haptics**: `HapticFeedback.lightImpact()` on checkbox toggle
- **Empty States**: Custom illustrated empty states for no tasks and no search results

---

## Technical Decisions

### Why Isar over SQLite/Hive?
Isar is modern, type-safe, and extremely fast. Its `build_runner` codegen approach ensures compile-time safety on all queries, and it offers native Flutter support. SQLite requires a bridge layer (sqflite) which adds boilerplate; Hive lacks the query capabilities needed for filtering/searching.

### Why Riverpod over Provider/Bloc?
Riverpod 2's compile-time safety, `ref.invalidate()` for targeted cache invalidation, and testability make it perfect for Track B's "state management excellence" requirement. It avoids the `BuildContext` dependency issues of Provider.

### 2-Second Delay Implementation
The delay is applied only to `createTask()` and `updateTask()` in `TaskRepository` via `Future.delayed(const Duration(seconds: 2))` before the Isar write transaction. Quick-toggle (checkbox) and delete bypass this intentionally — instant feedback is better UX for these actions.

### Draft Singleton Design
The draft is always stored at `id=1` in the `TaskDraft` Isar collection. This makes `put/get/delete(1)` O(1) and avoids needing to query for the "latest" draft. Only create mode (not edit mode) generates drafts.

---

## AI Usage Report

This project was built with the assistance of **Gemini (Antigravity)**.

### Most Helpful Prompts
- "Annotate Task and TaskDraft models with Isar @collection. Use @ignore on computed getters."
- "Create a premium Material 3 theme with Inter font, indigo palette, and proper CardThemeData."
- "Rebuild TaskCard with fade-in AnimationController, AnimatedOpacity for blocked state, HighlightedText in title and description."

### Examples of Bad AI Code (and Fixes)
- **Bad**: AI initially used `Isar.autoIncrement` directly in a `Task()` field assignment inside the form dialog, which doesn't make sense — Isar assigns IDs during `writeTxn`. **Fix**: Changed to `id = 0` (which Isar treats as auto-increment).
- **Bad**: AI used `CardTheme` where `CardThemeData` was required by `ThemeData.cardTheme`. **Fix**: Corrected the type.
- **Bad**: AI used `TaskRepository().isar.writeTxn(...)` (creating a new instance) inside `_toggleComplete`. **Fix**: Changed to use the singleton `_repository.isar`.
