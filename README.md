# Task Flow - Task Management App

**Track B - Mobile Specialist** submission for Flodo AI Flutter Assignment

## 🎯 Project Overview
A polished task management application built with Flutter, showcasing mobile development expertise with advanced features like debounced search, draft persistence, and blocked task dependencies.

## ✨ Features (In Progress)

### Core Features
- [ ] CRUD operations for tasks (Create, Read, Update, Delete)
- [ ] 2-second delay simulation on save operations
- [ ] Draft persistence (auto-save form data)
- [ ] Blocked tasks with visual distinction
- [ ] Search tasks by title
- [ ] Filter tasks by status
- [ ] Material Design 3 polished UI

### Stretch Goal
- [ ] **Debounced Autocomplete Search** (300ms delay)
- [ ] Real-time text highlighting in search results
- [ ] Performance optimized

## 🏗️ Tech Stack

- **Flutter**: 3.x
- **State Management**: Riverpod (compile-safe, reactive)
- **Database**: Isar (fastest NoSQL for Flutter)
- **Architecture**: Clean Architecture (simplified)
- **UI**: Material Design 3

## 📁 Project Structure

```
lib/
├── models/          # Data structures (Task, TaskDraft)
├── providers/       # State management (Riverpod providers)
├── repositories/    # Data layer (CRUD operations)
├── screens/         # Full-page UI components
├── widgets/         # Reusable UI components
├── theme/           # App styling and colors
└── utils/           # Helper functions (Debouncer, etc.)
```

## 🚀 Setup Instructions

### Prerequisites
- Flutter 3.x or higher
- Dart 3.x or higher

### Installation

1. Clone the repository
   ```bash
   git clone <your-repo-url>
   cd task_flow
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Generate Isar database code
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app
   ```bash
   flutter run
   ```

## 📋 Development Progress

- [x] Phase 1: Project setup and dependencies ✅
- [ ] Phase 2: Data models and database schema
- [ ] Phase 3: Repository implementation
- [ ] Phase 4: State management setup
- [ ] Phase 5: UI screens and widgets
- [ ] Phase 6: Core CRUD functionality
- [ ] Phase 7: Search and filter
- [ ] Phase 8: Stretch goal implementation
- [ ] Phase 9: UI/UX polish
- [ ] Phase 10: Testing and documentation

## 🎥 Demo Video
(Link will be added upon completion)

## 🤖 AI Usage Report
(Will be documented during development)

---

Developed with ❤️ using Flutter for Flodo AI
