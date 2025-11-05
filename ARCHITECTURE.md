# Architecture Documentation

## Overview

WorkoutTracker follows a modern iOS architecture using SwiftUI for the presentation layer and SwiftData for persistence. The app is structured around feature-based modules with clear separation of concerns.

## Architecture Pattern

### MVVM with SwiftData

```
┌─────────────────────────────────────────────────────────────┐
│                         Views (SwiftUI)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Track   │  │   PRs    │  │  Goals   │  │ Analyze  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │ @Query / @State
┌───────────────────────▼─────────────────────────────────────┐
│                    View Models (Optional)                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │  TrackScreenViewModel (Complex business logic)     │    │
│  └────────────────────────────────────────────────────┘    │
└───────────────────────┬─────────────────────────────────────┘
                        │ @Environment(\.modelContext)
┌───────────────────────▼─────────────────────────────────────┐
│                    SwiftData Models                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Exercise │  │   Goal   │  │ Strength │  │  Cardio  │   │
│  │          │  │          │  │   Set    │  │ Session  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                      Persistence                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  SwiftData Store (SQLite-backed)                   │    │
│  │  FileManager (Images)                              │    │
│  │  UserDefaults (Preferences)                        │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Read Operations
```
View → @Query → SwiftData → Model Objects → View Rendering
```

### Write Operations
```
User Action → View → ModelContext.insert() → SwiftData → Persistence
```

### Complex Queries
```
View → ViewModel → Fetch Descriptors → SwiftData → Processed Data → View
```

## Core Components

### 1. Models Layer

All models use SwiftData's `@Model` macro for automatic persistence.

#### Exercise.swift
```
Purpose: Defines exercise templates (e.g., "Bench Press", "Squats")
Relationships: One-to-many with StrengthSet, Goal
Key Properties:
  - name: Exercise name
  - muscleGroup: Primary muscle targeted
  - isCardio: Boolean flag for cardio exercises
```

#### StrengthSet.swift
```
Purpose: Logs individual strength training sets
Relationships: Many-to-one with Exercise
Key Properties:
  - reps: Number of repetitions
  - weight: Weight in kilograms (converted for display)
  - date: Timestamp of the set
  - exerciseID: Reference to Exercise
```

#### CardioSession.swift
```
Purpose: Logs cardio workout sessions
Relationships: Many-to-one with Exercise
Key Properties:
  - duration: Time in seconds
  - distance: Distance in kilometers (converted for display)
  - date: Timestamp of session
  - exerciseID: Reference to Exercise
```

#### Goal.swift
```
Purpose: User-defined fitness goals with progress tracking
Key Properties:
  - kind: Enum (strength, cardio, trackable, weight)
  - cadence: Enum (oneTime, daily, weekly, monthly, yearly)
  - direction: Enum (increase, decrease)
  - targetValue: Numeric goal
  - deadline: Optional target date

Logic:
  - Progress calculated by GoalProgressService
  - Aggregates data based on cadence period
```

#### TrackableItem.swift
```
Purpose: Custom user-defined metrics
Examples: Water intake, sleep hours, steps
Key Properties:
  - name: Metric name
  - unit: Unit of measurement
  - icon: SF Symbol name
```

#### TrackableLog.swift
```
Purpose: Individual logs for trackable items
Relationships: Many-to-one with TrackableItem
Key Properties:
  - value: Numeric value logged
  - date: Timestamp
  - trackableID: Reference to TrackableItem
```

### 2. Views Layer

#### Navigation Structure

```
RootTabView (Custom Tab Bar)
├── Track Tab
│   ├── TrackView (Main screen)
│   ├── AddTrackingSheet (Add new entries)
│   ├── AddSetSheet (Strength entry form)
│   ├── AddCardioSheet (Cardio entry form)
│   └── LogTrackableEntrySheet (Custom trackable form)
│
├── PRs Tab
│   └── PRsView (Personal records list)
│
├── Goals Tab
│   ├── GoalsView (Goals list)
│   └── GoalEditorView (Create/edit goals)
│
├── Analyze Tab
│   ├── AnalyzeView (Main analytics screen)
│   ├── ExerciseAnalyzeSection (Exercise-specific charts)
│   └── WeightAnalyzeSection (Body weight charts)
│
└── Journal Tab
    └── JournalView (Daily journal with photos)
```

#### Custom Tab Bar Implementation

**Why Custom?**
iOS's native TabView only supports 5 tabs before introducing a "More" menu. To provide a seamless experience with all 5 tabs visible, we implement a custom tab bar.

**Implementation** (RootTabView.swift:32-79):
```swift
VStack {
    ZStack {
        switch selection {
        case .track: NavigationStack { TrackView() }
        case .prs: NavigationStack { PRsView() }
        // ... other tabs
        }
    }
    Divider()
    HStack {
        ForEach(Tab.allCases) { tab in
            Button { selection = tab } label: {
                VStack {
                    Image(systemName: tab.systemImage)
                    Text(tab.title)
                }
            }
        }
    }
    .background(.ultraThinMaterial)
}
```

Benefits:
- All 5 tabs always visible
- Custom styling and animations
- No "More" overflow menu
- Full control over tab bar appearance

### 3. Services Layer

#### ImageStore.swift
```
Purpose: Manages journal photo persistence
Location: App Documents directory
Methods:
  - save(imageData:) → UUID
  - load(uuid:) → UIImage?
  - delete(uuid:)

Storage Path: FileManager.default.documentDirectory/images/{uuid}.jpg
```

#### GoalProgressService.swift
```
Purpose: Calculates goal progress based on cadence
Key Method: calculateProgress(goal:, context:) → (current, target, percentage)

Logic by Cadence:
  - OneTime: Sum all entries since goal creation
  - Daily: Sum entries for current day
  - Weekly: Sum entries for current week (Mon-Sun)
  - Monthly: Sum entries for current month
  - Yearly: Sum entries for current year

Supports: Strength, Cardio, Trackable, Weight goals
```

### 4. Utilities Layer

#### Date+Only.swift
```
Extension: Date.dayOnly
Purpose: Strips time component for day-based queries
Usage: Comparing dates, grouping by day
```

#### Units.swift
```
Purpose: Unit conversion and user preferences
Key Functions:
  - kg ↔ lbs conversion
  - km ↔ miles conversion
  - formatWeight(kg: Double, usePounds: Bool)
  - formatDistance(km: Double, useMiles: Bool)

Storage: UserDefaults keys
  - "usesPounds" → Bool
  - "usesMiles" → Bool
```

#### Formatters.swift
```
Purpose: Consistent number and date formatting
Shared Formatters:
  - numberFormatter (1 decimal place)
  - dateFormatter (short dates)
  - timeFormatter (HH:MM:SS)
```

#### TrackableCatalog.swift
```
Purpose: Predefined trackable templates
Examples:
  - Water (oz)
  - Steps (count)
  - Sleep (hours)
  - Calories (kcal)
```

#### MuscleGroups.swift
```
Purpose: Exercise categorization
Categories:
  - Chest, Back, Shoulders
  - Arms (Biceps, Triceps)
  - Legs (Quads, Hamstrings, Calves)
  - Core, Cardio
```

## Data Relationships

```
Exercise (1) ──────────< (many) StrengthSet
    │
    └──────────────────< (many) CardioSession
    │
    └──────────────────< (many) Goal (optional)

TrackableItem (1) ─────< (many) TrackableLog
    │
    └──────────────────< (many) Goal (optional)

JournalEntry (1:1 per day)
    └── photos: [UUID] → ImageStore

WeightEntry (many per user)
```

## Query Patterns

### Simple Queries (Direct @Query)
```swift
@Query(sort: \Exercise.name) var exercises: [Exercise]
```

### Filtered Queries
```swift
@Query(
    filter: #Predicate<StrengthSet> { set in
        set.date >= startDate && set.date <= endDate
    },
    sort: \.date
) var sets: [StrengthSet]
```

### Complex Queries (Fetch Descriptor)
```swift
let descriptor = FetchDescriptor<StrengthSet>(
    predicate: #Predicate { $0.exerciseID == exercise.id },
    sortBy: [SortDescriptor(\.date, order: .reverse)]
)
let sets = try? modelContext.fetch(descriptor)
```

## State Management

### Environment Objects
```swift
@Environment(\.modelContext) private var modelContext
```
- Injected at app root (WorkoutTrackerApp.swift)
- Available to all child views
- Used for all database operations

### App Storage (User Preferences)
```swift
@AppStorage("usesPounds") private var usesPounds = false
@AppStorage("usesMiles") private var usesMiles = false
```
- Persists user preferences
- Automatically syncs across views
- Backed by UserDefaults

### Local State
```swift
@State private var selectedDate = Date()
@State private var showingAddSheet = false
```
- View-specific state
- Not persisted
- Resets on view dismissal

## Performance Considerations

### Lazy Loading
- SwiftData queries are lazy by default
- Use `.prefix()` or pagination for large datasets
- Charts sample data for better performance

### Image Optimization
- Images compressed to JPEG (0.8 quality)
- Maximum dimension: 1024px
- Stored on disk, not in database

### Query Optimization
- Fetch only needed properties
- Use predicates to filter at database level
- Avoid loading relationships unnecessarily

## Error Handling

### User-Facing Errors
```swift
enum UserFacingError: LocalizedError {
    case saveFailure
    case deleteFailure
    case imageLoadFailure

    var errorDescription: String? {
        // User-friendly messages
    }
}
```

### Logging
```swift
// AppLogger.swift
os_log("Failed to save: %@", type: .error, error.localizedDescription)
```

## Testing Strategy

### Unit Tests
- Service layer (GoalProgressService)
- Utility functions (Units, Formatters)
- Date extensions

### Integration Tests
- SwiftData operations
- Query predicates
- Image persistence

### UI Tests
- Critical user flows (add workout, create goal)
- Tab navigation
- Form validation

## Security & Privacy

### Data Privacy
- All data stored locally on device
- No network calls or analytics
- Photos stored in app sandbox (not Photos library)

### Data Persistence
- SwiftData encrypted at rest (iOS default)
- No sensitive data in UserDefaults
- App deletion removes all data

## Future Architecture Considerations

### Potential Enhancements

1. **Cloud Sync**
   - CloudKit integration for cross-device sync
   - Conflict resolution strategy needed
   - Maintain offline-first approach

2. **Export/Import**
   - JSON export of all data
   - CSV export for analysis
   - Import from other fitness apps

3. **Widgets**
   - Today's workout summary
   - Active goal progress
   - Weekly volume chart

4. **Watch App**
   - Quick workout logging
   - Real-time heart rate integration
   - Voice input for notes

5. **Advanced Analytics**
   - Machine learning for predictions
   - Trend detection
   - Plateau identification

## Dependency Map

```
Views
  ├── Models (via @Query)
  ├── Services (via @Environment or direct init)
  └── Utilities (imports)

Services
  ├── Models
  └── Utilities

Models
  └── Foundation (no internal dependencies)

Utilities
  └── Foundation (no internal dependencies)
```

**Key Principle**: Dependencies flow downward. Lower layers never import higher layers.

## Build Configuration

### Deployment Target
- Minimum: iOS 17.0
- Reason: SwiftData and Swift Charts availability

### Swift Version
- Swift 5.9+
- Swift 6 ready (explicit types for @Model)

### Frameworks Required
- SwiftUI
- SwiftData
- Charts
- Foundation
- UIKit (minimal, for UIImage)

## Code Style Guidelines

### Naming Conventions
- Models: Singular nouns (Exercise, Goal)
- Views: Descriptive + "View" suffix (TrackView, GoalsView)
- Services: Descriptive + "Service" suffix (ImageStore, GoalProgressService)

### File Organization
- One primary type per file
- Related extensions in same file
- Shared components in Utilities/

### SwiftUI Best Practices
- Extract subviews for reusability
- Use `private` for view-only state
- Prefer `@State` over `@StateObject` when possible

---

**Last Updated**: 2025-01-05
**Version**: 1.0
