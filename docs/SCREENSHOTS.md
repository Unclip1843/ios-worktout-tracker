# 📸 Screenshots Guide

This guide shows you how to capture and add screenshots to make the documentation visual and professional.

## Screenshots Needed

### 1. App Overview (5 Core Screens)
- [ ] **Track Tab** - Main workout tracking view with today's workouts
- [ ] **PRs Tab** - Personal records list with highlighted achievements
- [ ] **Goals Tab** - Active goals with progress bars
- [ ] **Analyze Tab** - Charts and analytics view
- [ ] **Journal Tab** - Daily journal with photo attachments

### 2. Key Workflows (Action Shots)
- [ ] **Add Workout Flow** - Sheet with exercise selection and form
- [ ] **Create Goal Modal** - Goal editor with all options visible
- [ ] **Chart Detail** - Full-screen chart with data points
- [ ] **Journal Entry** - Journal with photos attached
- [ ] **Settings Screen** - Unit preferences and options

### 3. Details & Features
- [ ] **Swipe Navigation** - Visual showing swipe gesture
- [ ] **Custom Tab Bar** - All 5 tabs visible without "More"
- [ ] **Progress Indicators** - Goal progress visualization
- [ ] **Date Picker** - Custom date selection UI
- [ ] **Empty States** - First-time user experience

## How to Capture Screenshots

### Method 1: iOS Simulator (Recommended)

1. **Build and Run the App**
   ```bash
   cd WorkoutTrackerFull
   open WorkoutTracker.xcodeproj
   # In Xcode: Select iPhone 15 simulator, press ⌘R
   ```

2. **Add Sample Data**
   - Add 2-3 exercises
   - Log several sets/cardio sessions
   - Create 2-3 goals
   - Add a journal entry with photo
   - Log some body weight entries

3. **Capture Screenshots**
   - Navigate to each screen
   - Press `⌘S` in simulator to save screenshot
   - Screenshots save to Desktop by default

4. **Name Convention**
   ```
   01-track-view.png
   02-prs-view.png
   03-goals-view.png
   04-analyze-view.png
   05-journal-view.png
   06-add-workout-sheet.png
   07-goal-editor.png
   08-chart-detail.png
   ```

### Method 2: Physical Device

1. Build and run on your iPhone
2. Take screenshots: Press `Side Button + Volume Up`
3. AirDrop or email to your Mac
4. Rename files according to convention

## Image Requirements

### Size & Format
- **Format**: PNG (preferred) or JPG
- **Max Width**: 1170px (iPhone 15 Pro Max width)
- **Aspect Ratio**: Maintain device aspect ratio
- **File Size**: Under 500KB each (compress if needed)

### Optimization
```bash
# Install ImageOptim (optional)
brew install imageoptim-cli

# Optimize all screenshots
imageoptim docs/screenshots/*.png
```

## Adding Screenshots to README

1. **Save screenshots to** `docs/screenshots/`

2. **Update README.md** with image links:
   ```markdown
   ## 📱 Screenshots

   <div align="center">

   ### Main Features

   <table>
   <tr>
   <td><img src="docs/screenshots/01-track-view.png" alt="Track" width="200"/></td>
   <td><img src="docs/screenshots/02-prs-view.png" alt="PRs" width="200"/></td>
   <td><img src="docs/screenshots/03-goals-view.png" alt="Goals" width="200"/></td>
   </tr>
   <tr>
   <td align="center"><b>Track Workouts</b></td>
   <td align="center"><b>Personal Records</b></td>
   <td align="center"><b>Goals</b></td>
   </tr>
   </table>

   </div>
   ```

3. **Commit and push**:
   ```bash
   git add docs/screenshots/*.png README.md
   git commit -m "docs: add app screenshots"
   git push
   ```

## Creating Demo GIFs (Advanced)

### Tools
- **macOS**: Kap (free, open-source)
- **Alternatives**: QuickTime + Gifski, LICEcap

### Recording Tips
1. **Keep it short**: 5-10 seconds max
2. **Show one feature**: Focus on single workflow
3. **Smooth interactions**: Slow down actions slightly
4. **Optimize file size**: Aim for under 2MB

### Demo GIF Ideas
- Adding a workout (5s)
- Creating a goal (5s)
- Swiping between days (3s)
- Viewing analytics (5s)
- Custom tab bar in action (3s)

### GIF Optimization
```bash
# Using Gifski (brew install gifski)
gifski -W 600 --fps 15 input.mov -o output.gif
```

## Marketing Assets (Optional)

### App Store Style Screenshots
Create promotional images with captions:

**Tools:**
- Figma (free)
- Sketch
- Photoshop

**Template:**
```
┌─────────────────────┐
│                     │
│   [Screenshot]      │
│                     │
│                     │
├─────────────────────┤
│  Feature Headline   │
│  Brief description  │
└─────────────────────┘
```

### Social Media Cards
- **Size**: 1200x630px (Twitter/LinkedIn)
- **Include**: App name, key feature, screenshot
- **Tool**: Canva (free templates)

## Example: Complete Screenshot Set

```
docs/
└── screenshots/
    ├── 01-track-view.png          # Main tracking screen
    ├── 02-prs-view.png            # Personal records
    ├── 03-goals-view.png          # Goals list with progress
    ├── 04-analyze-view.png        # Charts and analytics
    ├── 05-journal-view.png        # Journal with photos
    ├── 06-add-workout.png         # Add workout modal
    ├── 07-goal-editor.png         # Goal creation form
    ├── 08-chart-detail.png        # Full chart view
    ├── 09-settings.png            # Settings screen
    ├── 10-custom-tab-bar.png      # All 5 tabs visible
    ├── demo-add-workout.gif       # Quick demo of adding workout
    ├── demo-swipe-nav.gif         # Swipe navigation demo
    └── hero-image.png             # Combined promo image
```

## Checklist

Before marking as complete:
- [ ] Captured all 5 core screens
- [ ] Captured 3+ workflow screenshots
- [ ] Images are properly named
- [ ] Images are optimized (<500KB each)
- [ ] Added images to README.md
- [ ] Created at least 1 demo GIF
- [ ] Screenshots show realistic data (not empty states)
- [ ] All text is readable at thumbnail size
- [ ] Committed and pushed to GitHub

## Pro Tips

1. **Use Light Mode**: Screenshots look better in documentation
2. **Realistic Data**: Show actual workouts, not lorem ipsum
3. **Consistent Device**: Use same iPhone model for all shots
4. **Same Time**: Set simulator time to 9:41 (Apple's standard)
5. **Status Bar**: Keep it clean (full battery, good signal)
6. **Orientation**: Portrait only for consistency

## Resources

- [Apple's Screenshot Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/)
- [GitHub Markdown Image Syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#images)
- [Kap - Screen Recording](https://getkap.co/)
- [ImageOptim - Compression](https://imageoptim.com/)

---

**Need help?** Open an issue or check the [CONTRIBUTING.md](../CONTRIBUTING.md) guide.
