//
//  WorkoutSessionScreen.swift
//  Stronglifts
//
//  Created by Arthur Danylenko on 14.04.2026.
//

import SwiftUI

struct WorkoutSessionScreen: View {
    @State private var selection: Selection = .train
    @State private var activeExercise: Int? = 0

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                Text("Workout A")
                    .font(.system(size: 14, weight: .regular))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.chip))
            
            Picker("", selection: $selection) {
                Text("Workout").tag(Selection.train)
                Text("Warmup").tag(Selection.warmup)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            exerciseList
        }
        .preferredColorScheme(.light)
    }

    private var exerciseList: some View {
        ScrollView {
            let exercises: [Exercise] = [
                Exercise(title: "Squad", scheme: "5×5 20kg", tasks: tasks),
                Exercise(title: "Bench Press", scheme: "5×5 20kg", tasks: tasks),
                Exercise(title: "Barbell row", scheme: "5×5 30kg", tasks: tasks)
            ]
            
            VStack(spacing: 22) {
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    WorkoutSetView(exercise: exercise, showSlider: index == activeExercise, onExerciseCompleted: {
                            if let activeExercise {
                                if activeExercise < (exercises.count - 1) {
                                    self.activeExercise = activeExercise + 1
                                } else {
                                    self.activeExercise = nil
                                }
                            }
                        }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    let tasks: [WorkoutSet] = [
        WorkoutSet(reps: 5),
        WorkoutSet(reps: 5),
        WorkoutSet(reps: 5),
        WorkoutSet(reps: 5),
        WorkoutSet(reps: 5)
    ]
}

#Preview {
    WorkoutSessionScreen()
}

enum Selection: String {
    case train = "Workout"
    case warmup = "Warmup"
}

extension Color {
    static let accent = Color(red: 0.82, green: 0.16, blue: 0.28)
    static let chip = Color(red: 0.94, green: 0.94, blue: 0.96)
}
