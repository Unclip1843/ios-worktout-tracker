# Changelog

All notable changes to WorkoutTracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- Cloud sync via CloudKit
- Export data to JSON/CSV
- iOS Widgets for home screen
- Apple Watch companion app
- Workout templates
- Rest timer between sets
- Exercise video tutorials
- Social sharing features

---

## [1.0.0] - 2025-01-05

### Added - Core Features

#### 🏋️ Workout Tracking
- Track strength training with sets, reps, and weight
- Log cardio sessions with time and distance
- Create custom exercises
- Define custom trackables (water, sleep, steps, etc.)
- Daily workout summaries
- Swipe navigation between days

#### 🏆 Personal Records
- Automatic PR detection for best single set
- Best day volume tracking
- Per-exercise PR history
- Visual PR indicators

#### 🎯 Goals System
- Multiple goal types: strength, cardio, weight, custom trackables
- Flexible cadences: one-time, daily, weekly, monthly, yearly
- Automatic progress calculation
- Progress bars and percentage tracking
- Optional deadline support
- Increase/decrease direction options

#### 📊 Analytics & Charts
- Exercise volume over time charts
- Rep distribution analysis
- Weight progression tracking
- Body weight trend charts
- Customizable time ranges (week, month, 3 months, year, all time)
- Interactive Swift Charts

#### 📖 Journal
- Daily journal entries with text
- Photo attachments (compressed and stored locally)
- Swipe navigation between days
- Workout summaries integrated

#### ⚙️ Settings & Customization
- Unit preferences (imperial/metric)
- Distance: miles ↔ kilometers
- Weight: pounds ↔ kilograms
- Exercise management (create, edit, delete)
- Muscle group categorization
- Trackable catalog management

### Technical Highlights

#### Architecture
- SwiftUI for modern, declarative UI
- SwiftData for type-safe persistence
- MVVM architecture pattern
- Custom tab bar (5 tabs always visible, no "More" overflow)
- Local-first data storage (privacy-focused)

#### Data Management
- SwiftData models with @Model macro
- Efficient querying with FetchDescriptor
- UUID-based relationships
- Metric storage with on-demand unit conversion

#### Performance
- Lazy loading for large datasets
- Image compression (JPEG 0.8 quality, max 1024px)
- Chart data sampling for smooth rendering
- Optimized SwiftData queries

#### User Experience
- Zero friction onboarding (no signup)
- Smart defaults (pre-populated exercises)
- Instant feedback (PR notifications)
- Intuitive swipe gestures
- Empty state guidance

### Platform Support
- iOS 17.0+
- iPadOS 17.0+ (universal app)
- Built with Xcode 15.0+
- Swift 5.9+

### Dependencies
- None (pure SwiftUI + Apple frameworks)
- SwiftUI (UI framework)
- SwiftData (persistence)
- Swift Charts (data visualization)
- Foundation (core utilities)

---

## Version History

### Development Timeline

#### Phase 1: Foundation (Dec 2024)
- Project setup with SwiftUI + SwiftData
- Core data models defined
- Basic CRUD operations

#### Phase 2: Core Features (Dec 2024 - Jan 2025)
- Workout tracking implementation
- Goal system with cadence logic
- Analytics with Swift Charts
- Journal with photo support

#### Phase 3: Polish & Documentation (Jan 2025)
- Custom tab bar implementation
- Unit conversion system
- PR detection algorithm
- Comprehensive documentation
- Architecture guides
- User flow diagrams

---

## Breaking Changes

None yet (first release).

---

## Migration Guides

### From Beta to 1.0 (If Applicable)

If you were using a beta version:

1. **Data Migration**: SwiftData automatically migrates
2. **Units**: All data stored in metric; display preferences in Settings
3. **Photos**: Existing photos remain in app Documents

---

## Known Issues

### Current Limitations

1. **No Cloud Sync** - Data stays on device only
2. **No Export** - Cannot export data yet (planned for 1.1)
3. **No Apple Watch** - Requires iPhone (Watch app planned)
4. **No Widgets** - Home screen widgets coming in 1.2
5. **Portrait Only** - Landscape support not optimized

### Reported Bugs

None reported yet. Found a bug? [Report it here](https://github.com/Unclip1843/ios-worktout-tracker/issues).

---

## Upcoming Releases

### [1.1.0] - Planned Q1 2025

**Features:**
- Export data to JSON/CSV formats
- Import workouts from CSV
- Workout templates library
- Rest timer with notifications
- Exercise notes field

**Improvements:**
- Faster chart rendering
- Better iPad layout
- Enhanced search functionality

### [1.2.0] - Planned Q2 2025

**Features:**
- iOS Home Screen widgets
- Lock Screen widgets
- Siri Shortcuts integration
- Workout reminders

### [2.0.0] - Planned Q3 2025

**Major Features:**
- CloudKit sync (cross-device)
- Apple Watch companion app
- HealthKit integration
- Advanced analytics (ML predictions)

---

## Deprecation Warnings

None yet.

---

## Security Updates

### 1.0.0 Security Features
- All data encrypted at rest (iOS default)
- No network connections
- No third-party analytics
- Photos stored in sandboxed Documents directory
- No collection of personal information

---

## Performance Improvements

### 1.0.0 Optimizations
- SwiftData lazy loading
- Image compression pipeline
- Chart data sampling (max 100 points)
- Efficient query predicates
- Cached number formatters

---

## Documentation Changes

### 1.0.0 Documentation
- Comprehensive README with badges and tables
- Detailed ARCHITECTURE.md with diagrams
- Complete CONTRIBUTING.md guide
- User flow diagrams (USER_FLOWS.md)
- Screenshot guide (SCREENSHOTS.md)
- This CHANGELOG

---

## Contributors

### Core Team
- Lead Developer: [@Unclip1843](https://github.com/Unclip1843)

### Special Thanks
- Apple Developer Documentation
- SwiftUI Community
- Open Source Community

---

## Release Notes Template

For future releases:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Modified features

### Deprecated
- Soon-to-be removed features

### Removed
- Deleted features

### Fixed
- Bug fixes

### Security
- Security updates
```

---

## Links

- [GitHub Repository](https://github.com/Unclip1843/ios-worktout-tracker)
- [Issue Tracker](https://github.com/Unclip1843/ios-worktout-tracker/issues)
- [Documentation](README.md)
- [Architecture](ARCHITECTURE.md)
- [Contributing](CONTRIBUTING.md)

---

**Follow [@Unclip1843](https://github.com/Unclip1843) for updates!**
