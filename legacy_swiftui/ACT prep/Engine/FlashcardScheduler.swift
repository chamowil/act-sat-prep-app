//
//  FlashcardScheduler.swift
//  ACT prep
//
//  Spaced repetition for flashcards, using a simplified SM-2: each card carries
//  an ease factor and an interval that grows when you recall it and collapses
//  when you don't.
//

import Foundation
import Observation

enum RecallGrade: Int, CaseIterable, Identifiable {
    case forgot = 0
    case hard = 1
    case good = 2
    case easy = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .forgot: return "Forgot"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var symbolName: String {
        switch self {
        case .forgot: return "xmark"
        case .hard: return "tortoise.fill"
        case .good: return "checkmark"
        case .easy: return "hare.fill"
        }
    }
}

struct CardState: Codable, Hashable {
    var ease: Double = 2.5
    /// Days until the next review.
    var interval: Int = 0
    /// Consecutive successful recalls.
    var streak: Int = 0
    var dueDate: Date = .distantPast
    var seen: Bool = false
}

@Observable
final class FlashcardScheduler {
    static let shared = FlashcardScheduler()

    private let url: URL
    private(set) var states: [String: CardState]

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("flashcard_states.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: CardState].self, from: data) {
            states = decoded
        } else {
            states = [:]
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(states) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func state(for id: String) -> CardState { states[id] ?? CardState() }

    /// Cards from a deck that are due now, unseen cards first.
    func dueCards(in deck: FlashcardDeck, limit: Int = 20) -> [Flashcard] {
        let now = Date()
        let due = deck.cards.filter { state(for: $0.id).dueDate <= now }
        let unseen = due.filter { !state(for: $0.id).seen }
        let review = due.filter { state(for: $0.id).seen }
            .sorted { state(for: $0.id).dueDate < state(for: $1.id).dueDate }
        return Array((unseen + review).prefix(limit))
    }

    func dueCount(in deck: FlashcardDeck) -> Int {
        let now = Date()
        return deck.cards.filter { state(for: $0.id).dueDate <= now }.count
    }

    func learnedCount(in deck: FlashcardDeck) -> Int {
        deck.cards.filter { state(for: $0.id).streak >= 2 }.count
    }

    var totalDue: Int {
        StudyLibrary.shared.decks.reduce(0) { $0 + dueCount(in: $1) }
    }

    var totalLearned: Int {
        StudyLibrary.shared.decks.reduce(0) { $0 + learnedCount(in: $1) }
    }

    func record(cardId: String, grade: RecallGrade) {
        var s = state(for: cardId)
        s.seen = true

        switch grade {
        case .forgot:
            s.streak = 0
            s.interval = 0
            s.ease = max(1.3, s.ease - 0.2)
        case .hard:
            s.streak += 1
            s.interval = max(1, Int(Double(max(s.interval, 1)) * 1.2))
            s.ease = max(1.3, s.ease - 0.15)
        case .good:
            s.streak += 1
            s.interval = s.interval == 0 ? 1 : Int((Double(s.interval) * s.ease).rounded())
        case .easy:
            s.streak += 1
            s.interval = s.interval == 0 ? 3 : Int((Double(s.interval) * s.ease * 1.3).rounded())
            s.ease = min(3.0, s.ease + 0.15)
        }

        s.interval = min(s.interval, 180)
        // A forgotten card comes back in this same session rather than tomorrow.
        s.dueDate = s.interval == 0
            ? Date().addingTimeInterval(60)
            : Calendar.current.date(byAdding: .day, value: s.interval, to: Date()) ?? Date()

        states[cardId] = s
        persist()
    }

    func reset() {
        states = [:]
        try? FileManager.default.removeItem(at: url)
    }
}
