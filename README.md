# WorkoutTracker

A comprehensive iOS fitness tracking application built with SwiftUI and SwiftData for iOS 17+.

## Features

### Core Functionality

#### 🏋️ Workout Tracking
- **Strength Training**: Log exercises with sets, reps, and weight
- **Cardio Sessions**: Track time and distance for cardio activities
- **Custom Exercises**: Create and manage your own exercise library
- **Custom Trackables**: Define custom metrics to track (water intake, steps, etc.)
- **Daily Summaries**: View totals and progress for each day
- **Swipe Navigation**: Quick day-to-day navigation with swipe gestures

#### 🏆 Personal Records (PRs)
- Automatic PR detection for best single set
- Best day totals tracking
- Per-exercise PR history
- Visual indicators for new records

#### 🎯 Goals
- **Multiple Goal Types**:
  - Strength goals (e.g., "Bench press 225 lbs")
  - Cardio goals (e.g., "Run 5 miles")
  - Custom trackable goals
- **Time-based Cadences**: One-time, daily, weekly, monthly, yearly
- **Progress Tracking**: Visual progress bars and percentage completion
- **Deadline Support**: Set target dates for your goals
- **Direction Options**: Track increases (get stronger) or decreases (lose weight)

#### 📊 Analytics & Charts
- **Exercise Analysis**:
  - Volume over time (sets × reps × weight)
  - Rep distribution charts
  - Weight progression tracking
  - Customizable date ranges (week, month, 3 months, year, all time)
- **Weight Tracking**:
  - Body weight logging with timestamps
  - Trend visualization
  - BMI indicators (optional)
- **Cardio Analysis**: Distance and time charts

#### 📖 Journal
- Daily journal entries with rich text
- Photo attachments (stored in app Documents)
- Swipe navigation between days
- Workout summaries integrated with journal entries

#### ⚙️ Settings & Customization
- **Unit Preferences**:
  - Distance: Miles or Kilometers
  - Weight: Pounds or Kilograms
- **Exercise Management**: Create, edit, and organize exercises
- **Muscle Group Categorization**: Organize exercises by muscle groups
- **Trackable Catalog**: Manage custom metrics and units

## Technology Stack

- **Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+)
- **Charts**: Swift Charts framework
- **Architecture**: MVVM with SwiftData models
- **Minimum iOS Version**: iOS 17.0

## Project Structure

```
WorkoutTracker/
├── Models/                    # Data models using SwiftData
│   ├── Exercise.swift        # Exercise definitions
│   ├── StrengthSet.swift     # Strength workout logs
│   ├── CardioSession.swift   # Cardio workout logs
│   ├── Goal.swift            # User goals and targets
│   ├── JournalEntry.swift    # Daily journal entries
│   ├── WeightEntry.swift     # Body weight logs
│   ├── TrackableItem.swift   # Custom trackable definitions
│   └── TrackableLog.swift    # Custom trackable logs
│
├── Views/                     # SwiftUI views organized by feature
│   ├── Track/                # Workout tracking screens
│   ├── PRs/                  # Personal records view
│   ├── Goals/                # Goal management
│   ├── Analyze/              # Analytics and charts
│   ├── Journal/              # Journal entries
│   ├── Settings/             # App settings
│   ├── Shared/               # Reusable components
│   └── RootTabView.swift     # Main navigation
│
├── Services/                  # Business logic and services
│   ├── ImageStore.swift      # Photo persistence
│   └── GoalProgressService.swift  # Goal calculation logic
│
├── Utilities/                 # Helper functions and extensions
│   ├── Date+Only.swift       # Date utilities
│   ├── Formatters.swift      # Number and date formatting
│   ├── Units.swift           # Unit conversion logic
│   ├── TrackableCatalog.swift # Predefined trackables
│   ├── MuscleGroups.swift    # Exercise categorization
│   └── AppLogger.swift       # Logging utilities
│
└── Assets.xcassets/           # App icons and colors
```

## Getting Started

### Prerequisites

- macOS with Xcode 15.0 or later
- iOS 17.0+ device or simulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Unclip1843/ios-worktout-tracker.git
cd ios-worktout-tracker
```

2. Open the project in Xcode:
```bash
open WorkoutTracker.xcodeproj
```

3. Select your target device or simulator (iOS 17.0+)

4. Build and run (⌘R)

### First Run

On first launch, the app will:
- Initialize the SwiftData store
- Create default exercise templates
- Set up default unit preferences (can be changed in Settings)

## Usage Guide

### Tracking a Workout

1. Open the **Track** tab
2. Tap **+ Add** to log a new activity
3. Choose between:
   - **Strength**: Select exercise, enter sets/reps/weight
   - **Cardio**: Select activity, enter time/distance
   - **Custom**: Log any custom trackable
4. Save to record your workout

### Setting Goals

1. Navigate to **Goals** tab
2. Tap **+ New Goal**
3. Configure:
   - Goal type (strength, cardio, or custom)
   - Target value and unit
   - Cadence (one-time, daily, weekly, etc.)
   - Optional deadline
4. Track progress automatically as you log workouts

### Viewing Analytics

1. Go to **Analyze** tab
2. Select an exercise or metric
3. Choose a time range
4. View charts showing:
   - Volume progression
   - Rep distribution
   - Weight trends
   - Personal records

### Journal Entries

1. Open **Journal** tab
2. Tap on any day to add/edit entry
3. Write notes and attach photos
4. Swipe left/right to navigate days
5. Photos are automatically saved to app Documents

## Data Storage

- **SwiftData**: All workout data, goals, and journal entries
- **FileManager**: Photos stored in app Documents directory
- **UserDefaults**: App preferences (units, settings)
- **All data stays on-device**: No cloud sync (privacy-focused)

## Key Features in Detail

### Custom Tab Bar Implementation
The app uses a custom tab bar (not native TabView) to support 5 visible tabs without overflow. This ensures all navigation options remain accessible.

### Unit Conversion
All measurements are stored in metric (kg, km) internally and converted for display based on user preferences. This ensures data consistency across unit changes.

### Goal Progress Calculation
Goals intelligently aggregate data based on cadence:
- **Daily goals**: Sum values for the current day
- **Weekly goals**: Sum values for the current week
- **Monthly goals**: Sum values for the current month
- **One-time goals**: Cumulative progress since creation

### PR Detection
Personal records are automatically detected and updated:
- **Single Set PRs**: Best weight × reps for an exercise
- **Daily Volume PRs**: Highest total volume in a single day
- **Distance PRs**: Longest single cardio session

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and architecture details.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design and code organization.

## License

This project is available for personal and educational use.

## Acknowledgments

Built with SwiftUI, SwiftData, and Swift Charts.

---

**Minimum Requirements**: iOS 17.0+ | Xcode 15.0+
