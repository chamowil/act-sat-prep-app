//
//  Achievements.swift
//  ACT prep
//
//  Badges are derived from stored progress rather than stored themselves, so
//  they can never drift out of sync with the underlying data.
//

import Foundation
import SwiftUI

struct Badge: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let tint: Color
    let isEarned: Bool
    /// 0...1 toward earning it, for the ones that are countable.
    let progress: Double
}

enum Achievements {

    static func all() -> [Badge] {
        let progress = ProgressStore.shared
        let settings = UserSettings.shared
        let cards = FlashcardScheduler.shared
        let tutorials = TutorialProgress.shared

        let attempted = progress.totalPracticeAttempted
        let correct = progress.totalPracticeCorrect
        let exams = progress.examResults.count
        let best = progress.bestComposite ?? 0
        let streak = settings.streak
        let learned = cards.totalLearned
        let tutorialsDone = TutorialLibrary.shared.subjects
            .reduce(0) { $0 + tutorials.completedCount(for: $1) }

        func badge(_ id: String, _ title: String, _ detail: String, _ symbol: String,
                   _ tint: Color, _ value: Int, _ goal: Int) -> Badge {
            Badge(id: id, title: title, detail: detail, symbolName: symbol, tint: tint,
                  isEarned: value >= goal,
                  progress: goal > 0 ? min(1, Double(value) / Double(goal)) : 0)
        }

        var badges: [Badge] = [
            badge("first-steps", "First Steps", "Answer your first question",
                  "figure.walk", .blue, attempted, 1),
            badge("fifty", "Half Century", "Answer 50 questions",
                  "50.circle.fill", .blue, attempted, 50),
            badge("twofifty", "Serious Student", "Answer 250 questions",
                  "books.vertical.fill", .indigo, attempted, 250),
            badge("sharpshooter", "Sharpshooter", "Get 100 questions right",
                  "target", .green, correct, 100),
            badge("streak-3", "Warming Up", "Hit your daily goal 3 days running",
                  "flame", .orange, streak, 3),
            badge("streak-7", "Week Strong", "Hit your daily goal 7 days running",
                  "flame.fill", .orange, streak, 7),
            badge("streak-30", "Unstoppable", "Hit your daily goal 30 days running",
                  "crown.fill", .yellow, streak, 30),
            badge("first-exam", "Test Day Rehearsal", "Finish your first mock exam",
                  "flag.checkered", .purple, exams, 1),
            badge("five-exams", "Seasoned", "Finish 5 mock exams",
                  "checkmark.seal.fill", .purple, exams, 5),
            badge("score-24", "Above Average", "Score 24 or better on a mock exam",
                  "arrow.up.right.circle.fill", .teal, best, 24),
            badge("score-30", "Top Tier", "Score 30 or better on a mock exam",
                  "star.fill", .yellow, best, 30),
            badge("cards-50", "Card Shark", "Learn 50 flashcards",
                  "rectangle.on.rectangle.angled", .pink, learned, 50),
            badge("tutorials-10", "Well Read", "Complete 10 tutorials",
                  "book.fill", .cyan, tutorialsDone, 10),
            badge("tutorials-all", "Completionist", "Complete every tutorial",
                  "graduationcap.fill", .indigo, tutorialsDone, TutorialLibrary.shared.tutorials.count)
        ]

        // Goal badge only appears once the student has set a target worth chasing.
        badges.append(
            badge("hit-target", "Goal Reached", "Reach your target score of \(settings.targetScore)",
                  "trophy.fill", .yellow, best, settings.targetScore)
        )
        return badges
    }

    static var earnedCount: Int { all().filter(\.isEarned).count }
    static var totalCount: Int { all().count }
}
