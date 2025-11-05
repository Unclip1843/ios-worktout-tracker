import Foundation

struct TrackableTemplate: Identifiable {
    let id = UUID()
    let group: String
    let name: String
    let kind: TrackableItem.Kind
    let muscleGroups: [String]
    let tags: [String]
    let notes: String?
}

enum TrackableCatalog {
    static let templates: [TrackableTemplate] = [
        // Strength
        TrackableTemplate(group: "Strength Exercises", name: "Push-Ups", kind: .strengthExercise,
                          muscleGroups: ["Chest", "Shoulders", "Triceps", "Core"],
                          tags: ["bodyweight", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Pull-Ups", kind: .strengthExercise,
                          muscleGroups: ["Back", "Biceps", "Shoulders", "Core"],
                          tags: ["bodyweight", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Bench Press", kind: .strengthExercise,
                          muscleGroups: ["Chest", "Shoulders", "Triceps"],
                          tags: ["barbell", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Overhead Press", kind: .strengthExercise,
                          muscleGroups: ["Shoulders", "Triceps", "Core"],
                          tags: ["barbell", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Squats", kind: .strengthExercise,
                          muscleGroups: ["Quadriceps", "Glutes", "Hamstrings", "Core"],
                          tags: ["barbell", "lower-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Deadlifts", kind: .strengthExercise,
                          muscleGroups: ["Hamstrings", "Glutes", "Back", "Core"],
                          tags: ["barbell", "posterior-chain"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Lunges", kind: .strengthExercise,
                          muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
                          tags: ["bodyweight", "lower-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Hip Thrusts", kind: .strengthExercise,
                          muscleGroups: ["Glutes", "Hamstrings"],
                          tags: ["barbell", "posterior-chain"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Bent-Over Rows", kind: .strengthExercise,
                          muscleGroups: ["Back", "Biceps"],
                          tags: ["barbell", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Dips", kind: .strengthExercise,
                          muscleGroups: ["Chest", "Shoulders", "Triceps"],
                          tags: ["bodyweight", "upper-body"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Planks", kind: .strengthExercise,
                          muscleGroups: ["Core"],
                          tags: ["isometric", "bodyweight"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Mountain Climbers", kind: .strengthExercise,
                          muscleGroups: ["Core", "Shoulders"],
                          tags: ["bodyweight", "conditioning"], notes: nil),
        TrackableTemplate(group: "Strength Exercises", name: "Burpees", kind: .strengthExercise,
                          muscleGroups: ["Full Body"],
                          tags: ["bodyweight", "conditioning"], notes: nil),

        // Cardio
        TrackableTemplate(group: "Cardio", name: "Running", kind: .cardioExercise,
                          muscleGroups: ["Cardio"],
                          tags: ["aerobic", "endurance"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "Cycling", kind: .cardioExercise,
                          muscleGroups: ["Cardio", "Quadriceps"],
                          tags: ["aerobic", "endurance"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "Rowing", kind: .cardioExercise,
                          muscleGroups: ["Cardio", "Back", "Legs"],
                          tags: ["aerobic", "full-body"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "Swimming", kind: .cardioExercise,
                          muscleGroups: ["Cardio", "Full Body"],
                          tags: ["aerobic", "low-impact"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "Jump Rope", kind: .cardioExercise,
                          muscleGroups: ["Cardio", "Calves"],
                          tags: ["conditioning", "coordination"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "Stair Climb", kind: .cardioExercise,
                          muscleGroups: ["Cardio", "Glutes", "Quadriceps"],
                          tags: ["conditioning"], notes: nil),
        TrackableTemplate(group: "Cardio", name: "HIIT Circuit", kind: .cardioExercise,
                          muscleGroups: ["Full Body"],
                          tags: ["conditioning", "high-intensity"], notes: nil),

        // Mobility
        TrackableTemplate(group: "Mobility & Recovery", name: "Full-Body Stretch", kind: .custom,
                          muscleGroups: ["Mobility"],
                          tags: ["recovery", "mobility"], notes: "Track duration and key areas."),
        TrackableTemplate(group: "Mobility & Recovery", name: "Hamstring Stretch", kind: .custom,
                          muscleGroups: ["Hamstrings"],
                          tags: ["mobility", "recovery"], notes: nil),
        TrackableTemplate(group: "Mobility & Recovery", name: "Hip Flexor Stretch", kind: .custom,
                          muscleGroups: ["Hip Flexors"],
                          tags: ["mobility", "recovery"], notes: nil),
        TrackableTemplate(group: "Mobility & Recovery", name: "Shoulder Mobility Flow", kind: .custom,
                          muscleGroups: ["Shoulders"],
                          tags: ["mobility", "recovery"], notes: nil),
        TrackableTemplate(group: "Mobility & Recovery", name: "Foam Rolling Session", kind: .custom,
                          muscleGroups: ["Mobility"],
                          tags: ["myofascial-release", "recovery"], notes: "Track areas targeted."),

        // Wellness
        TrackableTemplate(group: "Wellness", name: "Sleep Log", kind: .custom,
                          muscleGroups: [],
                          tags: ["sleep", "wellness"], notes: "Log hours and quality."),
        TrackableTemplate(group: "Wellness", name: "Meditation Session", kind: .custom,
                          muscleGroups: [],
                          tags: ["mindfulness", "wellness"], notes: "Record duration and focus."),
        TrackableTemplate(group: "Wellness", name: "Breathwork / Relaxation", kind: .custom,
                          muscleGroups: [],
                          tags: ["breathwork", "stress-management"], notes: "Track protocol and duration."),

        // Nutrition
        TrackableTemplate(group: "Nutrition", name: "Breakfast", kind: .meal,
                          muscleGroups: [],
                          tags: ["meal", "nutrition"], notes: "Record macros or notes."),
        TrackableTemplate(group: "Nutrition", name: "Lunch", kind: .meal,
                          muscleGroups: [],
                          tags: ["meal", "nutrition"], notes: "Record macros or notes."),
        TrackableTemplate(group: "Nutrition", name: "Dinner", kind: .meal,
                          muscleGroups: [],
                          tags: ["meal", "nutrition"], notes: "Record macros or notes."),
        TrackableTemplate(group: "Nutrition", name: "Snack", kind: .meal,
                          muscleGroups: [],
                          tags: ["meal", "nutrition"], notes: "Record macros or notes."),
        TrackableTemplate(group: "Nutrition", name: "Post-Workout Shake", kind: .meal,
                          muscleGroups: [],
                          tags: ["recovery", "nutrition"], notes: "Track protein and carbs."),
        TrackableTemplate(group: "Nutrition", name: "Hydration Log", kind: .meal,
                          muscleGroups: [],
                          tags: ["hydration", "wellness"], notes: "Log fluid intake."),

        // Weight
        TrackableTemplate(group: "Weight", name: "Body Weight", kind: .weight,
                          muscleGroups: [],
                          tags: ["body", "progress"], notes: "Daily body weight entry.")
    ]

    static var groupedTemplates: [(title: String, items: [TrackableTemplate])] {
        let grouped = Dictionary(grouping: templates) { $0.group }
        let orderedGroups = [
            "Strength Exercises",
            "Cardio",
            "Mobility & Recovery",
            "Wellness",
            "Nutrition",
            "Weight"
        ]
        return orderedGroups.compactMap { title in
            guard let items = grouped[title] else { return nil }
            return (title, items)
        }
    }
}
