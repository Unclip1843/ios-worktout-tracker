# Contributing to WorkoutTracker

Thank you for your interest in contributing to WorkoutTracker! This document provides guidelines and information for developers.

> ⚠️ **Licensing Notice:** This project is released with all rights reserved. Please reach out via GitHub issues before reusing code outside the repository or distributing builds.

## Getting Started

### Development Environment Setup

1. **Prerequisites**
   - macOS 13.0+ (Ventura or later)
   - Xcode 15.0+
   - iOS 17.0+ simulator or device
   - Git

2. **Clone the Repository**
   ```bash
   git clone https://github.com/Unclip1843/ios-workout-tracker.git
   cd ios-workout-tracker
   ```

3. **Open in Xcode**
   ```bash
   open WorkoutTracker.xcodeproj
   ```

4. **Build and Run**
   - Select a simulator (iOS 17.0+)
   - Press ⌘R to build and run
   - No external dependencies or CocoaPods required

## Project Structure

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

### Quick Reference

```
WorkoutTracker/
├── Models/           # SwiftData models
├── Views/            # SwiftUI views by feature
├── Services/         # Business logic
├── Utilities/        # Helpers and extensions
└── Assets.xcassets/  # Images and colors
```

## Development Guidelines

### Code Style

#### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation (Xcode default)
- Max line length: 120 characters (soft limit)
- Use descriptive variable names (no abbreviations)

#### SwiftUI Conventions

```swift
// ✅ Good: Clear, descriptive names
struct TrackView: View {
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    var body: some View {
        // View code
    }
}

// ❌ Avoid: Unclear abbreviations
struct TV: View {
    @State private var dt = Date()
    @State private var showing = false
}
```

#### Property Order

```swift
struct MyView: View {
    // 1. Environment properties
    @Environment(\.modelContext) private var modelContext

    // 2. Query properties
    @Query private var exercises: [Exercise]

    // 3. State properties
    @State private var selectedDate = Date()

    // 4. AppStorage properties
    @AppStorage("usesPounds") private var usesPounds = false

    // 5. Regular properties
    let exercise: Exercise

    // 6. Body
    var body: some View {
        // ...
    }

    // 7. Private helper methods
    private func saveData() {
        // ...
    }
}
```

### SwiftData Best Practices

#### Model Definitions

```swift
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: String
    var isCardio: Bool
    var createdAt: Date

    init(name: String, muscleGroup: String, isCardio: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.isCardio = isCardio
        self.createdAt = Date()
    }
}
```

#### Key Rules for @Model

1. **Default Values**: Use fully qualified names
   ```swift
   // ✅ Correct
   var cadence: Cadence = Cadence.oneTime

   // ❌ Incorrect (will cause compiler error)
   var cadence: Cadence = .oneTime
   ```

2. **Unique Identifiers**: Use `@Attribute(.unique)` for IDs
   ```swift
   @Attribute(.unique) var id: UUID
   ```

3. **Relationships**: Use UUIDs for relationships (not direct references)
   ```swift
   // Store the ID
   var exerciseID: UUID

   // Fetch when needed
   let exercise = exercises.first { $0.id == exerciseID }
   ```

#### Database Operations

```swift
// Insert
let exercise = Exercise(name: "Bench Press", muscleGroup: "Chest")
modelContext.insert(exercise)
try? modelContext.save()

// Update
exercise.name = "New Name"
try? modelContext.save()

// Delete
modelContext.delete(exercise)
try? modelContext.save()

// Query
let descriptor = FetchDescriptor<Exercise>(
    predicate: #Predicate { $0.muscleGroup == "Chest" },
    sortBy: [SortDescriptor(\.name)]
)
let chestExercises = try? modelContext.fetch(descriptor)
```

### View Development

#### Component Extraction

Extract reusable components into separate views:

```swift
// ✅ Good: Extracted component
struct WorkoutCard: View {
    let exercise: Exercise
    let sets: [StrengthSet]

    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name)
            ForEach(sets) { set in
                SetRow(set: set)
            }
        }
    }
}

// Use it
WorkoutCard(exercise: exercise, sets: todaysSets)
```

#### State Management

```swift
// ✅ Use @State for view-local state
@State private var isEditing = false

// ✅ Use @Environment for shared context
@Environment(\.modelContext) private var modelContext

// ✅ Use @AppStorage for user preferences
@AppStorage("usesPounds") private var usesPounds = false

// ❌ Avoid @StateObject unless managing complex state
// (SwiftData handles most state management)
```

### Error Handling

#### User-Facing Errors

```swift
enum UserFacingError: LocalizedError {
    case saveFailure
    case loadFailure
    case invalidInput(String)

    var errorDescription: String? {
        switch self {
        case .saveFailure:
            return "Unable to save your changes. Please try again."
        case .loadFailure:
            return "Unable to load data. Please restart the app."
        case .invalidInput(let field):
            return "Invalid \(field). Please check your input."
        }
    }
}
```

#### Error Presentation

```swift
@State private var errorMessage: String?
@State private var showingError = false

// In your view
.alert("Error", isPresented: $showingError) {
    Button("OK") { }
} message: {
    Text(errorMessage ?? "An unknown error occurred")
}

// When error occurs
do {
    try modelContext.save()
} catch {
    errorMessage = error.localizedDescription
    showingError = true
}
```

### Testing

#### Unit Test Example

```swift
import XCTest
@testable import WorkoutTracker

final class UnitsTests: XCTestCase {
    func testKgToPoundsConversion() {
        let kg = 100.0
        let lbs = Units.kgToPounds(kg)
        XCTAssertEqual(lbs, 220.46, accuracy: 0.01)
    }

    func testPoundsToKgConversion() {
        let lbs = 220.46
        let kg = Units.poundsToKg(lbs)
        XCTAssertEqual(kg, 100.0, accuracy: 0.01)
    }
}
```

#### UI Test Example

```swift
import XCTest

final class WorkoutTrackerUITests: XCTestCase {
    func testAddWorkout() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Track tab
        app.buttons["Track"].tap()

        // Tap add button
        app.buttons["Add"].tap()

        // Select strength option
        app.buttons["Strength"].tap()

        // Verify sheet opened
        XCTAssertTrue(app.navigationBars["Add Set"].exists)
    }
}
```

## Adding New Features

### Feature Template

When adding a new feature, follow this structure:

1. **Define Model** (if needed)
   ```swift
   // Models/NewFeature.swift
   @Model
   final class NewFeature {
       @Attribute(.unique) var id: UUID
       // Properties...

       init(...) {
           // Initialization
       }
   }
   ```

2. **Create Views**
   ```swift
   // Views/NewFeature/NewFeatureView.swift
   struct NewFeatureView: View {
       @Environment(\.modelContext) private var modelContext
       @Query private var items: [NewFeature]

       var body: some View {
           // View implementation
       }
   }
   ```

3. **Add Navigation** (if new tab)
   ```swift
   // Update RootTabView.swift
   private enum Tab: String, CaseIterable {
       case track, prs, goals, analyze, journal, newFeature
   }
   ```

4. **Update Documentation**
   - Add feature description to README.md
   - Update ARCHITECTURE.md with new components
   - Document public APIs

### Example: Adding a "Workout Templates" Feature

1. **Model**
   ```swift
   @Model
   final class WorkoutTemplate {
       @Attribute(.unique) var id: UUID
       var name: String
       var exerciseIDs: [UUID]
       var defaultSets: Int
       var defaultReps: Int

       init(name: String, exerciseIDs: [UUID], defaultSets: Int, defaultReps: Int) {
           self.id = UUID()
           self.name = name
           self.exerciseIDs = exerciseIDs
           self.defaultSets = defaultSets
           self.defaultReps = defaultReps
       }
   }
   ```

2. **View**
   ```swift
   struct WorkoutTemplatesView: View {
       @Environment(\.modelContext) private var modelContext
       @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

       var body: some View {
           List(templates) { template in
               TemplateRow(template: template)
           }
           .navigationTitle("Templates")
       }
   }
   ```

3. **Integration**
   - Add to Settings or new tab
   - Provide UI to apply template
   - Update TrackView to support template creation

## Git Workflow

### Branch Naming

- `feature/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `refactor/component-name` - Code refactoring
- `docs/update-description` - Documentation updates

### Commit Messages

Follow conventional commits:

```
type(scope): brief description

Longer description if needed

- Bullet points for details
- Multiple changes explained
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `test`: Tests
- `chore`: Maintenance

Examples:
```
feat(goals): add weekly cadence option

- Implement weekly goal calculations
- Update GoalProgressService
- Add UI selector in GoalEditorView

fix(track): correct weight unit conversion

Weight was displaying in kg when user preference
was set to pounds. Fixed Units.formatWeight() call.

docs(readme): update installation instructions
```

### Pull Request Process

1. Create a feature branch
2. Make your changes
3. Test thoroughly (build, run, manual testing)
4. Update documentation if needed
5. Create pull request with:
   - Clear description of changes
   - Screenshots (for UI changes)
   - Testing steps
   - Related issue numbers

## Common Tasks

### Adding a New Exercise

```swift
let exercise = Exercise(
    name: "Pull-ups",
    muscleGroup: "Back",
    isCardio: false
)
modelContext.insert(exercise)
try? modelContext.save()
```

### Querying Data by Date Range

```swift
let startDate = Calendar.current.startOfDay(for: Date())
let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

let descriptor = FetchDescriptor<StrengthSet>(
    predicate: #Predicate { set in
        set.date >= startDate && set.date < endDate
    }
)
let todaySets = try? modelContext.fetch(descriptor)
```

### Adding a New Chart

```swift
import Charts

struct VolumeChart: View {
    let data: [(Date, Double)]

    var body: some View {
        Chart(data, id: \.0) { date, volume in
            LineMark(
                x: .value("Date", date),
                y: .value("Volume", volume)
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day))
        }
    }
}
```

## Debugging Tips

### SwiftData Issues

```swift
// Enable SwiftData logging
// Add to scheme environment variables:
// SWIFTDATA_ENABLE_LOGGING = 1
```

### Common Issues

1. **"Default value requires fully qualified name"**
   - Use `Cadence.oneTime` not `.oneTime` in @Model classes

2. **"Failed to save context"**
   - Check for unique constraint violations
   - Verify all required properties are set

3. **Views not updating**
   - Ensure using @Query for SwiftData
   - Check that modelContext.save() is called

## Resources

- [Swift.org Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Questions?

- Open an issue for bugs or feature requests
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design questions
- Review [README.md](README.md) for general usage

---

**Happy Coding!** 💪
