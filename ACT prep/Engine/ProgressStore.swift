//
//  ProgressStore.swift
//  ACT prep
//

import Foundation
import Observation

/// Persists exam results and practice statistics as JSON in the app's
/// documents directory.
@Observable
final class ProgressStore {
    static let shared = ProgressStore()

    private(set) var examResults: [ExamResult] = []
    /// questionId → was the last practice attempt correct
    private(set) var practiceOutcomes: [String: Bool] = [:]

    private let resultsURL: URL
    private let practiceURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        resultsURL = docs.appendingPathComponent("exam_results.json")
        practiceURL = docs.appendingPathComponent("practice_outcomes.json")
        load()
    }

    private func load() {
        if let data = try? Data(contentsOf: resultsURL),
           let items = try? JSONDecoder().decode([ExamResult].self, from: data) {
            examResults = items
        }
        if let data = try? Data(contentsOf: practiceURL),
           let items = try? JSONDecoder().decode([String: Bool].self, from: data) {
            practiceOutcomes = items
        }
    }

    func save(result: ExamResult) {
        examResults.append(result)
        if let data = try? JSONEncoder().encode(examResults) {
            try? data.write(to: resultsURL, options: .atomic)
        }
    }

    func recordPractice(questionId: String, correct: Bool) {
        practiceOutcomes[questionId] = correct
        if let data = try? JSONEncoder().encode(practiceOutcomes) {
            try? data.write(to: practiceURL, options: .atomic)
        }
    }

    // MARK: Derived stats

    var bestComposite: Int? { examResults.map(\.composite).max() }

    var latestComposite: Int? { examResults.sorted { $0.date < $1.date }.last?.composite }

    func practiceStats(for subject: Subject) -> (attempted: Int, correct: Int) {
        let qs = QuestionBank.shared.questions(for: subject)
        var attempted = 0, correct = 0
        for q in qs {
            if let outcome = practiceOutcomes[q.id] {
                attempted += 1
                if outcome { correct += 1 }
            }
        }
        return (attempted, correct)
    }

    var totalPracticeAttempted: Int { practiceOutcomes.count }
    var totalPracticeCorrect: Int { practiceOutcomes.values.filter { $0 }.count }

    func resetAll() {
        examResults = []
        practiceOutcomes = [:]
        try? FileManager.default.removeItem(at: resultsURL)
        try? FileManager.default.removeItem(at: practiceURL)
    }
}
