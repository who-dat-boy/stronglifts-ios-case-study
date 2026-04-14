//
//  Exercise.swift
//  Stronglifts
//
//  Created by Arthur Danylenko on 14.04.2026.
//

import Foundation

struct Exercise: Identifiable {
    let id = UUID()
    let title: String
    let scheme: String
    let tasks: [WorkoutSet]
}
