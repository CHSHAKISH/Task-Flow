# Task Flow - Flodo AI Assignment

A polished Task Management Flutter application built as a submission for the Flodo AI Take-Home Assignment.

## 🚀 Track & Stretch Goal Details
- **Track Chosen:** Track B (Mobile Specialist)
- **Stretch Goals Completed:**
  1. **Debounced Autocomplete Search:** Filters the list as the user types with a non-blocking debounce delay modifying lists and search highlighting dynamically.
  2. **Recurring Tasks Logic:** Supports toggling features for tasks where marking a task as "Done" auto-generates duplicates with the next due date while keeping the original task completed.
  3. **Persistent Drag-and-Drop:** Intuitive drag-to-reorder functionality allowing users to shift task priority effectively and persisting the custom user-defined sequence seamlessly across app restarts.
  
## 📱 Core Features
- **Task Management:** Full CRUD operations seamlessly integrated.
- **Architectural UI Restrictions:** Implemented visual grouping where dependent/blocked tasks appear visibly grayed-out safely disabling interactions until its requirement (blocked-by task) is marked sequentially as Done.
- **Intelligent Draft Persistence:** If navigating away or minimizing the app whilst typing out a new task form, the app gracefully saves the incomplete drafts intrinsically utilizing WidgetsBindingObserver via AppLifecycleState monitoring. Handily retrieving content precisely where you left off when selecting "Resume Draft".
- **Search & Filtering:** Functional interactive UI that lets users text-search matching explicit substrings natively connected to filtering out Task Statuses via responsive FilterChips.
- **Simulated Latency Strategy:** Specifically architectured to explicitly handle mathematical fake 2-second delays mimicking network latency for Create and Update operations smoothly, avoiding UI-locking and duplicate executions.

## ⚙️ Setup & Run Instructions

**1. Prerequisites:**
Ensure you have the Flutter SDK locally installed and appropriately configured with an active iOS Simulator, Android Emulator, or a connected physical device.

**2. Clone the Repository:**
``bash
git clone <your-repo-link>
cd task_flow
``

**3. Install Dependencies:**
Fetch all required dependencies:
``bash
flutter pub get
``

*(Note: If code-generation is needed for the data layer based on schema structural changes, run: flutter pub run build_runner build --delete-conflicting-outputs)*

**4. Run the Project:**
Compile and launch natively:
``bash
flutter run
``

## 🤖 AI Usage Report
AI tools were thoughtfully integrated as significant productivity multipliers across this assignment's sprint timeline. 
**Models used:** GitHub Copilot (utilizing Gemini 3.1 Pro Preview).

**Most Helpful Prompts utilized:**
1. *"Architect a declarative Riverpod state-management plan extracting heavy inline UI code inside main.dart to neatly abstracted modular Provider components orchestrating decoupled Search/Filter logic."*
2. *"Implement a resilient WidgetsBindingObserver lifecycle hook safely indexing the active text controllers before abruptly closing the form interface to securely serialize drafts locally responding to AppLifecycleState.paused logic without memory leaks."*
3. *"Construct an optimal Dismissible widget structurally verifying Swipe-To-Delete gesture operations combining AlertDialog safety layers successfully mapped to Repository triggers."*

**Examples of bad AI code & resolutions:**
- **The Issue:** While extracting the TaskFormDialog out of main.dart into a cleaner component structure, the AI initially attempted to bind the draft's explicit WidgetsBindingObserver listening state entirely globally while referencing locally destroyed component Form states causing saving operations to inherently execute 
ull!
- **The Fix:** Architecturally restructured the component relationship by migrating the explicit lifecycle observer hooks locally inside the encapsulated custom TaskFormDialog widget inherently so text values corresponded truthfully to the active scope.
