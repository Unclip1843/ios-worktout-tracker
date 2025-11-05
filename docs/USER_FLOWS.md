# 🔄 User Flows

Complete user journey diagrams for WorkoutTracker's core features.

---

## Table of Contents

- [First Time User Journey](#first-time-user-journey)
- [Track Workout Flow](#track-workout-flow)
- [Create Goal Flow](#create-goal-flow)
- [View Analytics Flow](#view-analytics-flow)
- [Journal Entry Flow](#journal-entry-flow)
- [Settings & Customization](#settings--customization)

---

## First Time User Journey

```mermaid
graph TD
    A[App Launch] --> B{First Time?}
    B -->|Yes| C[Initialize SwiftData]
    B -->|No| D[Load Existing Data]

    C --> E[Create Default Exercises]
    E --> F[Set Default Preferences<br/>Imperial/Metric]
    F --> G[Show Track Tab]

    D --> G

    G --> H[Empty State:<br/>Add Your First Workout]
    H --> I{User Action}

    I -->|Tap Add| J[Start Tracking]
    I -->|Explore Tabs| K[Browse Features]
    I -->|Settings| L[Customize Units]

    style A fill:#4A90E2
    style G fill:#7ED321
    style J fill:#F5A623
```

**Key Moments:**
1. **Instant Start** - No signup, no onboarding screens
2. **Smart Defaults** - Pre-populated exercises (Bench Press, Squats, etc.)
3. **Guided Discovery** - Empty states guide user to first action

---

## Track Workout Flow

### Flow Diagram

```mermaid
graph TD
    A[Track Tab] --> B[Tap + Add Button]
    B --> C[Choose Workout Type]

    C --> D[Strength]
    C --> E[Cardio]
    C --> F[Custom Trackable]

    D --> D1[Select Exercise]
    D1 --> D2[Enter Reps]
    D2 --> D3[Enter Weight]
    D3 --> D4[Tap Save]
    D4 --> D5[✅ Set Logged]
    D5 --> D6{PR Detected?}
    D6 -->|Yes| D7[🎉 Show PR Badge]
    D6 -->|No| D8[Update Today's Summary]
    D7 --> D8
    D8 --> A

    E --> E1[Select Cardio Exercise]
    E1 --> E2[Enter Duration]
    E2 --> E3[Enter Distance<br/>Optional]
    E3 --> E4[Tap Save]
    E4 --> E5[✅ Session Logged]
    E5 --> A

    F --> F1[Select Trackable]
    F1 --> F2[Enter Value]
    F2 --> F3[Tap Save]
    F3 --> F4[✅ Log Saved]
    F4 --> A

    style A fill:#4A90E2
    style D5 fill:#7ED321
    style D7 fill:#F5A623
    style E5 fill:#7ED321
```

### Step-by-Step: Strength Workout

| Step | Screen | Action | Result |
|------|--------|--------|--------|
| 1 | Track Tab | User lands on main screen | Sees today's workouts + Add button |
| 2 | Track Tab | Taps "+" button | Modal sheet appears |
| 3 | Add Modal | Selects "Strength" | Opens Add Set sheet |
| 4 | Add Set Sheet | Picks "Bench Press" from list | Exercise selected |
| 5 | Add Set Sheet | Enters reps: 10 | Number validated |
| 6 | Add Set Sheet | Enters weight: 135 lbs | Converted to 61.2 kg internally |
| 7 | Add Set Sheet | Taps "Save" | Sheet dismisses |
| 8 | Track Tab | Set appears in list | Volume calculated, PR checked |
| 9 | Track Tab (if PR) | 🏆 Badge appears | User gets instant feedback |

### Error Handling

```mermaid
graph TD
    A[Enter Invalid Data] --> B{Validation}
    B -->|Empty Reps| C[Show Error:<br/>Reps required]
    B -->|Empty Weight| D[Show Error:<br/>Weight required]
    B -->|Zero/Negative| E[Show Error:<br/>Must be positive]
    B -->|Valid| F[Save to Database]

    C --> G[User Corrects]
    D --> G
    E --> G
    G --> B

    F --> H{Save Success?}
    H -->|Yes| I[Dismiss & Update UI]
    H -->|No| J[Show Error Alert]
    J --> K[Retry or Cancel]

    style F fill:#7ED321
    style I fill:#7ED321
    style C fill:#D0021B
    style D fill:#D0021B
    style E fill:#D0021B
    style J fill:#D0021B
```

---

## Create Goal Flow

### Flow Diagram

```mermaid
graph TD
    A[Goals Tab] --> B[Tap + New Goal]
    B --> C[Goal Editor Opens]

    C --> D[Enter Goal Title]
    D --> E[Select Goal Type]

    E --> F[Strength]
    E --> G[Cardio]
    E --> H[Weight]
    E --> I[Custom Trackable]

    F --> F1[Pick Exercise]
    F1 --> F2[Set Target Volume]

    G --> G1[Pick Cardio Activity]
    G1 --> G2[Set Target Distance/Time]

    H --> H1[Set Target Weight]

    I --> I1[Pick Trackable]
    I1 --> I2[Set Target Value]

    F2 --> J[Select Cadence]
    G2 --> J
    H1 --> J
    I2 --> J

    J --> K{Cadence?}
    K -->|One-time| L[Set Deadline<br/>Optional]
    K -->|Daily| L
    K -->|Weekly| L
    K -->|Monthly| L
    K -->|Yearly| L

    L --> M[Select Direction]
    M --> N{Increase or Decrease?}
    N -->|Increase| O[Goal: Get Stronger/More]
    N -->|Decrease| P[Goal: Reduce/Less]

    O --> Q[Add Note<br/>Optional]
    P --> Q

    Q --> R[Tap Create]
    R --> S[✅ Goal Created]
    S --> T[Goals Tab Updates]
    T --> U[Auto-calculate Progress]

    style A fill:#4A90E2
    style S fill:#7ED321
    style U fill:#7ED321
```

### Goal Progress Calculation

```mermaid
graph LR
    A[Goal Created] --> B{Cadence Type}

    B -->|One-time| C[Sum ALL entries<br/>since creation]
    B -->|Daily| D[Sum TODAY's entries]
    B -->|Weekly| E[Sum THIS WEEK's entries<br/>Mon-Sun]
    B -->|Monthly| F[Sum THIS MONTH's entries]
    B -->|Yearly| G[Sum THIS YEAR's entries]

    C --> H[Calculate Percentage]
    D --> H
    E --> H
    F --> H
    G --> H

    H --> I[Current ÷ Target × 100]
    I --> J[Update Progress Bar]
    J --> K{Reached Target?}
    K -->|Yes| L[🎉 Mark Complete]
    K -->|No| M[Show Progress %]

    style L fill:#7ED321
    style M fill:#F5A623
```

---

## View Analytics Flow

### Flow Diagram

```mermaid
graph TD
    A[Analyze Tab] --> B[Exercise List<br/>+ Body Weight]

    B --> C{User Selection}

    C -->|Select Exercise| D[Exercise Detail View]
    C -->|Select Body Weight| E[Weight Trends View]

    D --> D1[Show Date Range Picker]
    D1 --> D2{Time Range}
    D2 -->|Week| D3[Load 7 days data]
    D2 -->|Month| D4[Load 30 days data]
    D2 -->|3 Months| D5[Load 90 days data]
    D2 -->|Year| D6[Load 365 days data]
    D2 -->|All Time| D7[Load all data]

    D3 --> D8[Query SwiftData]
    D4 --> D8
    D5 --> D8
    D6 --> D8
    D7 --> D8

    D8 --> D9[Calculate Metrics]
    D9 --> D10[Volume Over Time Chart]
    D9 --> D11[Rep Distribution Chart]
    D9 --> D12[Weight Progression Chart]
    D9 --> D13[PR Indicators]

    E --> E1[Query Weight Entries]
    E1 --> E2[Generate Line Chart]
    E2 --> E3[Show Trend Line]
    E3 --> E4[Display Stats<br/>Current, High, Low, Avg]

    style D10 fill:#4A90E2
    style D11 fill:#4A90E2
    style D12 fill:#4A90E2
```

### Chart Generation Process

```mermaid
sequenceDiagram
    participant User
    participant View
    participant ViewModel
    participant SwiftData
    participant Charts

    User->>View: Select Exercise + Range
    View->>ViewModel: Request chart data
    ViewModel->>SwiftData: FetchDescriptor query
    SwiftData-->>ViewModel: Return sets/sessions
    ViewModel->>ViewModel: Process & aggregate data
    ViewModel->>ViewModel: Sample if > 100 points
    ViewModel-->>View: Return chart data
    View->>Charts: Render chart
    Charts-->>User: Display interactive chart
```

---

## Journal Entry Flow

### Flow Diagram

```mermaid
graph TD
    A[Journal Tab] --> B[Calendar View]
    B --> C[Select Date]

    C --> D{Entry Exists?}
    D -->|No| E[Show Empty State]
    D -->|Yes| F[Load Entry]

    E --> G[Tap to Add Entry]
    F --> H[Show Entry Content]

    G --> I[Entry Editor]
    H --> I

    I --> J[Write Text]
    J --> K{Add Photos?}
    K -->|Yes| L[Tap Photo Button]
    K -->|No| M[Tap Save]

    L --> N[Photo Picker Opens]
    N --> O[Select Photos]
    O --> P[Compress & Resize]
    P --> Q[ImageStore.save]
    Q --> R[Store UUIDs in Entry]
    R --> M

    M --> S[Save to SwiftData]
    S --> T[✅ Entry Saved]
    T --> U[Back to Calendar]

    U --> V[Swipe Left/Right]
    V --> W[Navigate Days]
    W --> B

    style T fill:#7ED321
```

### Photo Management

```mermaid
graph TD
    A[User Selects Photo] --> B[UIImagePickerController]
    B --> C[Get UIImage]

    C --> D[Check Dimensions]
    D --> E{Width or Height > 1024?}
    E -->|Yes| F[Resize to 1024px max]
    E -->|No| G[Keep Original Size]

    F --> H[Convert to JPEG Data]
    G --> H

    H --> I[Compress at 0.8 quality]
    I --> J[Generate UUID]
    J --> K[Save to Documents/images/]
    K --> L[Return UUID]
    L --> M[Add to photoUUIDs array]
    M --> N[Save JournalEntry]

    style N fill:#7ED321
```

---

## Settings & Customization

### Flow Diagram

```mermaid
graph TD
    A[Settings Tab] --> B{Setting Type}

    B -->|Unit Preferences| C[Toggle Distance]
    B -->|Unit Preferences| D[Toggle Weight]
    B -->|Exercises| E[Manage Exercises]
    B -->|Trackables| F[Manage Trackables]

    C --> C1{Miles or Kilometers?}
    C1 -->|Miles| C2[Save usesMiles = true]
    C1 -->|Kilometers| C3[Save usesMiles = false]
    C2 --> C4[All distances re-display]
    C3 --> C4

    D --> D1{Pounds or Kilograms?}
    D1 -->|Pounds| D2[Save usesPounds = true]
    D1 -->|Kilograms| D3[Save usesPounds = false]
    D2 --> D4[All weights re-display]
    D3 --> D4

    E --> E1[Exercise List]
    E1 --> E2{Action}
    E2 -->|Add| E3[Create New Exercise]
    E2 -->|Edit| E4[Modify Existing]
    E2 -->|Delete| E5[Remove Exercise]
    E3 --> E6[Save to SwiftData]
    E4 --> E6
    E5 --> E7[Confirm Deletion]
    E7 -->|Confirm| E8[Delete from DB]
    E7 -->|Cancel| E1

    F --> F1[Trackables Catalog]
    F1 --> F2{Action}
    F2 -->|Add| F3[Create Custom Trackable]
    F2 -->|Edit| F4[Modify Trackable]
    F3 --> F5[Define Name, Unit, Icon]
    F5 --> F6[Save to SwiftData]

    style C4 fill:#7ED321
    style D4 fill:#7ED321
    style E6 fill:#7ED321
```

---

## Decision Trees

### What Should I Track?

```mermaid
graph TD
    A[What do you want to track?] --> B{Exercise Type}

    B -->|Weights/Resistance| C[Use Strength Tracking]
    B -->|Running/Swimming| D[Use Cardio Tracking]
    B -->|Steps/Water/Sleep| E[Use Custom Trackables]
    B -->|Body Changes| F[Use Weight Logging]

    C --> C1[Track sets, reps, weight]
    C1 --> C2[See volume charts]
    C2 --> C3[Get PR notifications]

    D --> D1[Track time & distance]
    D1 --> D2[See distance charts]
    D2 --> D3[Monitor pace trends]

    E --> E1[Define your metric]
    E1 --> E2[Set custom unit]
    E2 --> E3[Log daily values]
    E3 --> E4[Set goals if desired]

    F --> F1[Log weight regularly]
    F1 --> F2[See trend chart]
    F2 --> F3[Track progress over time]
```

### When to Create a Goal?

```mermaid
graph TD
    A[Want to Set a Goal?] --> B{Goal Type}

    B -->|Performance Target| C[e.g., Bench 225 lbs]
    B -->|Consistency Goal| D[e.g., Run 3x per week]
    B -->|Volume Target| E[e.g., 50,000 lbs total]
    B -->|Body Composition| F[e.g., Reach 180 lbs]

    C --> G[Select Exercise]
    G --> H[Set Target Weight × Reps]
    H --> I[Choose One-time]
    I --> J[Set Deadline]

    D --> K[Select Cardio Activity]
    K --> L[Set Target: 3 sessions]
    L --> M[Choose Weekly]

    E --> N[Select Exercise]
    N --> O[Set Target Volume]
    O --> P[Choose Daily/Weekly/Monthly]

    F --> Q[Use Weight Goal Type]
    Q --> R[Set Target Weight]
    R --> S[Choose One-time]
    S --> T[Set Deadline]
```

---

## Navigation Patterns

### Tab Navigation Flow

```mermaid
graph LR
    A[Track] -.->|Swipe/Tap| B[PRs]
    B -.->|Swipe/Tap| C[Goals]
    C -.->|Swipe/Tap| D[Analyze]
    D -.->|Swipe/Tap| E[Journal]
    E -.->|Swipe/Tap| A

    A -->|Tap Track| A
    B -->|Tap PRs| B
    C -->|Tap Goals| C
    D -->|Tap Analyze| D
    E -->|Tap Journal| E

    style A fill:#4A90E2
    style B fill:#F5A623
    style C fill:#7ED321
    style D fill:#BD10E0
    style E fill:#FF6B6B
```

### Deep Linking Patterns

```
Track Workout → PR Detected → Tap Badge → Navigate to PRs Tab
Goal Progress → Tap Goal → Shows Contributing Workouts → Tap Workout → Navigate to Track Tab
Chart View → Tap Data Point → Shows Sets for That Day → Navigate to Track Tab (That Date)
Journal → View Photos → Tap Photo → Full Screen View → Swipe Gallery
```

---

## Error States & Edge Cases

### No Data States

```mermaid
graph TD
    A[User Opens Feature] --> B{Has Data?}

    B -->|No| C[Show Empty State]
    B -->|Yes| D[Show Data]

    C --> E{Which Feature?}
    E -->|Track| F["No workouts yet<br/>Tap + to get started"]
    E -->|PRs| G["No records yet<br/>Complete workouts to see PRs"]
    E -->|Goals| H["No goals yet<br/>Tap + to set your first goal"]
    E -->|Analyze| I["No data to analyze<br/>Track workouts to see charts"]
    E -->|Journal| J["No entry for this day<br/>Tap to add entry"]

    F --> K[Tap CTA Button]
    G --> K
    H --> K

    K --> L[Open Appropriate Form]

    style C fill:#F5A623
```

### Network/Storage Errors

```mermaid
graph TD
    A[Action Attempted] --> B{Storage Available?}
    B -->|No| C[Show Error Alert]
    B -->|Yes| D{Save Success?}

    D -->|No| E[Log Error]
    D -->|Yes| F[Update UI]

    E --> G[Show User Alert]
    G --> H{User Choice}
    H -->|Retry| A
    H -->|Cancel| I[Return to Previous Screen]

    C --> J["Cannot save<br/>Storage full or unavailable"]
    J --> K[User Acknowledges]
    K --> I

    style C fill:#D0021B
    style E fill:#D0021B
    style F fill:#7ED321
```

---

## Performance Optimizations

### Data Loading Strategy

```mermaid
graph TD
    A[App Launch] --> B[Load Recent Data Only]
    B --> C[Load Last 7 Days Workouts]
    C --> D[Load Active Goals]
    D --> E[Load Current Month Weight]

    E --> F[User Navigates to Analyze]
    F --> G{Large Dataset?}
    G -->|Yes| H[Load with Pagination]
    G -->|No| I[Load All Data]

    H --> J[Fetch First 100 Records]
    J --> K[User Scrolls]
    K --> L[Lazy Load Next 100]

    style B fill:#7ED321
    style H fill:#F5A623
```

---

## Accessibility Flows

### VoiceOver Navigation

```
Track Tab:
"Track. Tab 1 of 5. Selected."
"Add workout button. Double-tap to add a new workout."
"Today's Workouts. Heading."
"Bench Press. 3 sets. Total volume 3,150 pounds."
```

### Dynamic Type Support

```mermaid
graph LR
    A[User Changes Text Size] --> B[iOS Notification]
    B --> C[SwiftUI Auto-scales]
    C --> D[Fonts Adjust]
    D --> E[Layouts Reflow]
    E --> F[All Text Readable]

    style F fill:#7ED321
```

---

## Key Takeaways

1. **Zero Friction** - No signup, instant tracking
2. **Smart Defaults** - Pre-populated exercises, intuitive units
3. **Instant Feedback** - PR detection, progress updates
4. **Flexible Goals** - Multiple cadences for any fitness objective
5. **Privacy First** - All data local, no network calls

---

**For implementation details, see [ARCHITECTURE.md](../ARCHITECTURE.md)**
**For contributing, see [CONTRIBUTING.md](../CONTRIBUTING.md)**
