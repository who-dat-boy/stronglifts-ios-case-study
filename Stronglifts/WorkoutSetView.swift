//
//  WorkoutSetView.swift
//  Stronglifts
//
//  Created by Arthur Danylenko on 14.04.2026.
//

import SwiftUI

struct WorkoutSetView: View {
    @Namespace var completeness
    @State private var completedByID: [UUID: Int] = [:]
    @State private var sourceTaskIDs: [UUID] = []
    @State private var activeTask: Int?
    @State private var isAnimatingCompletion = false
    
    @State private var offset: CGFloat = .zero
    @State private var checkedRep: Int?
    private let moverSize: CGFloat = 52
    
    let exercise: Exercise
    let showSlider: Bool
    let onExerciseCompleted: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(exercise.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(exercise.scheme)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.accent)
            }
            .font(.system(size: 16, weight: .regular))
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                VStack(spacing: 5) {
                    if showSlider, let activeTask {
                        WorkoutSetStatus(activeTask: activeTask, checkedRep: checkedRep)
                        
                        WorkoutRepsSlider(
                            sourceTaskIDs: sourceTaskIDs,
                            activeTaskID: exercise.tasks[activeTask].id,
                            repsCount: exercise.tasks[activeTask].reps,
                            moverSize: moverSize,
                            completeness: completeness,
                            offset: $offset,
                            checkedRep: $checkedRep
                        ) { rate in
                            let completedTaskID = exercise.tasks[activeTask].id
                            isAnimatingCompletion = true
                            
                            withAnimation(.bouncy) {
                                sourceTaskIDs.removeAll(where: { $0 == completedTaskID })
                                completedByID[completedTaskID] = rate
                            } completion: {
                                withAnimation(.bouncy(duration: 0.15)) {
                                    offset = .zero
                                    checkedRep = nil
                                    
                                    self.activeTask = exercise.tasks.firstIndex(where: {
                                        sourceTaskIDs.contains($0.id)
                                    })
                                    
                                    if self.activeTask == nil {
                                        onExerciseCompleted()
                                    }
                                } completion: {
                                    isAnimatingCompletion = false
                                }
                            }
                        }
                        .frame(height: moverSize)
                        .padding(8)
                        .background(Capsule().fill(.red.opacity(0.1)))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 5)
                        .zIndex(10)
                        .allowsHitTesting(!isAnimatingCompletion)
                    }
                }
                .zIndex(10)
                
                WorkoutSetChips(tasks: exercise.tasks, completedByID: completedByID, completeness: completeness)
                    .zIndex(0)
            }
        }
        .onAppear(perform: setup)
        .onChange(of: showSlider) { isVisible in
            if isVisible, activeTask == nil, completedByID.count < exercise.tasks.count {
                activeTask = exercise.tasks.firstIndex(where: { sourceTaskIDs.contains($0.id) })
            } else if !isVisible {
                activeTask = nil
                offset = .zero
                checkedRep = nil
            }
        }
    }
    
    func setup() {
        if sourceTaskIDs.isEmpty {
            sourceTaskIDs = exercise.tasks.map(\.id)
        }

        activeTask = (showSlider && !exercise.tasks.isEmpty)
        ? exercise.tasks.firstIndex(where: { sourceTaskIDs.contains($0.id) })
            : nil
    }
}

private struct WorkoutSetStatus: View {
    let activeTask: Int
    let checkedRep: Int?

    var body: some View {
        HStack {
            Text("Set #\(activeTask + 1)")
                .font(.system(size: 12, weight: .regular))

            Spacer()

            Group {
                if let checkedRep {
                    Text("\(checkedRep) \(checkedRep > 1 ? "reps" : "rep")")
                } else {
                    Text("Slide to enter reps")
                }
            }
            .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 16)
    }
}

private struct WorkoutRepsSlider: View {
    let sourceTaskIDs: [UUID]
    let activeTaskID: UUID
    let repsCount: Int
    let moverSize: CGFloat
    let completeness: Namespace.ID
    @Binding var offset: CGFloat
    @Binding var checkedRep: Int?
    let onCommit: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let safeRepsCount = max(1, repsCount)
            let available = max(1, geo.size.width - (moverSize + 16))

            HStack(spacing: 0) {
                ZStack {
                    ForEach(sourceTaskIDs, id: \.self) { sourceID in
                        ZStack {
                            Circle().fill(.red)

                            Group {
                                if sourceID == activeTaskID {
                                    if let checkedRep {
                                        Text("\(checkedRep)")
                                            .font(.system(size: 14, weight: .bold))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .matchedGeometryEffect(
                            id: sourceID,
                            in: completeness,
                            isSource: true
                        )
                        .opacity(sourceID == activeTaskID ? 1 : 0)
                        .offset(x: sourceID == activeTaskID ? offset : 0)
                        .allowsHitTesting(sourceID == activeTaskID)
                        .zIndex(sourceID == activeTaskID ? 20 : 0)
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .frame(width: moverSize, height: moverSize)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let move = value.translation.width

                            guard move > 0 else {
                                checkedRep = nil
                                return
                            }

                            let bound = min(max(0, move), geo.size.width - (moverSize + 16))
                            offset = bound

                            let nextCheck = available / CGFloat(safeRepsCount)
                            let rep = Int(ceil(bound / nextCheck))
                            checkedRep = min(max(1, rep), repsCount)
                        }
                        .onEnded { value in
                            guard offset > 0 else { return }

                            let nextCheck = available / CGFloat(safeRepsCount)
                            let rate = min(max(1, Int(ceil(offset / nextCheck))), repsCount)
                            onCommit(rate)
                        }
                )
                .zIndex(20)

                HStack(spacing: 0) {
                    ForEach(0..<repsCount, id: \.self) { ri in
                        Rectangle()
                            .fill(ri == (repsCount - 1) ? .black : .gray)
                            .frame(maxWidth: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 10)
                .padding(.trailing, 16)
                .zIndex(1)
            }
        }
    }
}

private struct WorkoutSetChips: View {
    let tasks: [WorkoutSet]
    let completedByID: [UUID: Int]
    let completeness: Namespace.ID

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(tasks) { task in
                    let completion = completedByID[task.id]

                    ZStack {
                        if let completion {
                            ZStack {
                                Circle()
                                    .fill(completion == task.reps ? .red : .pink)

                                Text("\(completion)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .matchedGeometryEffect(
                                id: task.id,
                                in: completeness,
                                isSource: false
                            )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.chip)
                                
                                Text("\(task.reps)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.gray.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 52, height: 52)
                }

                Circle()
                    .fill(Color.chip)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Text("+")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.gray.opacity(0.7))
                    }
            }
            .padding(.horizontal, 16)
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
    }
}

#Preview {
    WorkoutSetView(
        exercise: Exercise(title: "Squat", scheme: "5x5 40kg", tasks: [
            .init(reps: 5), .init(reps: 5), .init(reps: 5), .init(reps: 5), .init(reps: 5)
        ]),
        showSlider: true,
        onExerciseCompleted: {}
    )
}
