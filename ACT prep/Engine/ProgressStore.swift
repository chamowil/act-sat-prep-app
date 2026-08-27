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

    // MARK: Topic-level analysis

    struct TopicStat: Identifiable, Hashable {
        let subject: Subject
        let topic: String
        let attempted: Int
        let correct: Int
        var id: String { "\(subject.rawValue)-\(topic)" }
        var accuracy: Double { attempted > 0 ? Double(correct) / Double(attempted) : 0 }
    }

    /// Accuracy per topic for one subject, including topics not yet attempted so
    /// the heatmap shows the full syllabus.
    func topicStats(for subject: Subject) -> [TopicStat] {
        var attempted: [String: Int] = [:]
        var correct: [String: Int] = [:]
        for q in QuestionBank.shared.questions(for: subject) {
            attempted[q.topic] = attempted[q.topic] ?? 0
            correct[q.topic] = correct[q.topic] ?? 0
            if let outcome = practiceOutcomes[q.id] {
                attempted[q.topic, default: 0] += 1
                if outcome { correct[q.topic, default: 0] += 1 }
            }
        }
        return attempted.keys.sorted().map {
            TopicStat(subject: subject, topic: $0,
                      attempted: attempted[$0] ?? 0, correct: correct[$0] ?? 0)
        }
    }

    /// Topics the student is measurably weakest at, across every subject.
    /// Only topics with enough attempts to be meaningful are considered.
    func weakestTopics(limit: Int = 5, minimumAttempts: Int = 3) -> [TopicStat] {
        Subject.allCases
            .flatMap { topicStats(for: $0) }
            .filter { $0.attempted >= minimumAttempts && $0.accuracy < 0.8 }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(limit)
            .map { $0 }
    }

    /// Estimated composite, blending mock exam results with practice accuracy.
    /// Exams are weighted far more heavily because they are timed and complete.
    func predictedComposite(includeScience: Bool) -> Int? {
        let subjects = includeScience ? Subject.allCases : Subject.allCases.filter { $0 != .science }

        let examScores: [Int] = examResults
            .sorted { $0.date < $1.date }
            .suffix(3)
            .map { result in
                let sections = result.sections.filter { subjects.contains($0.subject) }
                return ACTScoring.composite(sections.map(\.scaled))
            }

        var practiceScaled: [Int] = []
        for subject in subjects {
            let stats = practiceStats(for: subject)
            guard stats.attempted >= 5 else { continue }
            practiceScaled.append(ACTScoring.scaledScore(correct: stats.correct, total: stats.attempted))
        }

        let examAvg = examScores.isEmpty
            ? nil : Double(examScores.reduce(0, +)) / Double(examScores.count)
        let practiceAvg = practiceScaled.isEmpty
            ? nil : Double(practiceScaled.reduce(0, +)) / Double(practiceScaled.count)

        switch (examAvg, practiceAvg) {
        case let (e?, p?): return Int((e * 0.75 + p * 0.25).rounded())
        case let (e?, nil): return Int(e.rounded())
        case let (nil, p?): return Int(p.rounded())
        default: return nil
        }
    }

    func resetAll() {
        examResults = []
        practiceOutcomes = [:]
        try? FileManager.default.removeItem(at: resultsURL)
        try? FileManager.default.removeItem(at: practiceURL)
    }
}
