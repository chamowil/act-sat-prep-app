//
//  Models.swift
//  ACT prep
//

import Foundation

enum Subject: String, Codable, CaseIterable, Identifiable {
    case english, math, reading, science

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .math: return "Math"
        case .reading: return "Reading"
        case .science: return "Science"
        }
    }

    var symbolName: String {
        switch self {
        case .english: return "text.book.closed.fill"
        case .math: return "function"
        case .reading: return "book.pages.fill"
        case .science: return "atom"
        }
    }

    /// Full-length section: question count and minutes (enhanced ACT format).
    var fullCount: Int {
        switch self {
        case .english: return 50
        case .math: return 45
        case .reading: return 36
        case .science: return 40
        }
    }

    var fullMinutes: Int {
        switch self {
        case .english: return 35
        case .math: return 50
        case .reading: return 40
        case .science: return 40
        }
    }

    /// Quick mock section: question count and minutes.
    var quickCount: Int {
        switch self {
        case .english: return 15
        case .math: return 12
        case .reading: return 10
        case .science: return 10
        }
    }

    var quickMinutes: Int {
        switch self {
        case .english: return 10
        case .math: return 13
        case .reading: return 11
        case .science: return 10
        }
    }
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let subject: Subject
    var passageId: String?
    let topic: String
    let difficulty: Int
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
}

struct Passage: Codable, Identifiable, Hashable {
    let id: String
    let subject: Subject
    let title: String
    let text: String
}

// MARK: - Question bank

final class QuestionBank {
    static let shared = QuestionBank()

    private(set) var questions: [Question] = []
    private(set) var passages: [String: Passage] = [:]
    private(set) var bySubject: [Subject: [Question]] = [:]

    private init() {
        load()
    }

    private func load() {
        let questionFiles = ["english_questions", "math_questions", "reading_questions", "science_questions"]
        let passageFiles = ["english_passages", "reading_passages", "science_passages"]
        let decoder = JSONDecoder()

        for name in questionFiles {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let items = try? decoder.decode([Question].self, from: data) else { continue }
            questions.append(contentsOf: items)
        }
        for name in passageFiles {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let items = try? decoder.decode([Passage].self, from: data) else { continue }
            for p in items { passages[p.id] = p }
        }
        bySubject = Dictionary(grouping: questions, by: \.subject)
    }

    func questions(for subject: Subject) -> [Question] {
        bySubject[subject] ?? []
    }

    func topics(for subject: Subject) -> [String] {
        Array(Set(questions(for: subject).map(\.topic))).sorted()
    }

    func passage(for question: Question) -> Passage? {
        question.passageId.flatMap { passages[$0] }
    }

    /// Deterministic slice of a subject's questions for a given mock exam.
    /// Rotates through the bank so consecutive exams overlap as little as possible,
    /// and keeps passage-based questions grouped by walking passages in rotated order.
    func examQuestions(subject: Subject, examIndex: Int, count: Int) -> [Question] {
        let pool = questions(for: subject)
        guard !pool.isEmpty else { return [] }

        if subject == .math {
            let start = (examIndex * count) % pool.count
            return (0..<min(count, pool.count)).map { pool[(start + $0) % pool.count] }
        }

        // Passage-based subjects: rotate whole passages so sets stay coherent.
        var byPassage: [String: [Question]] = [:]
        var order: [String] = []
        for q in pool {
            let key = q.passageId ?? q.id
            if byPassage[key] == nil { order.append(key) }
            byPassage[key, default: []].append(q)
        }
        guard !order.isEmpty else { return [] }
        var result: [Question] = []
        var idx = examIndex % order.count
        while result.count < count {
            let group = byPassage[order[idx]] ?? []
            result.append(contentsOf: group.prefix(count - result.count))
            idx = (idx + 1) % order.count
            if idx == examIndex % order.count && result.isEmpty { break }
        }
        return result
    }
}

// MARK: - Scoring

enum ACTScoring {
    /// Approximate percent-correct → ACT scaled score (1–36).
    static func scaledScore(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 1 }
        let pct = Double(correct) / Double(total)
        let scaled = 1.0 + pct * 35.0
        // Real curves are gentler at the top; nudge high percentages up slightly.
        let adjusted = pct >= 0.9 ? min(36.0, scaled + 1.0) : scaled
        return max(1, min(36, Int(adjusted.rounded())))
    }

    static func composite(_ sectionScores: [Int]) -> Int {
        guard !sectionScores.isEmpty else { return 1 }
        let avg = Double(sectionScores.reduce(0, +)) / Double(sectionScores.count)
        return max(1, min(36, Int(avg.rounded())))
    }
}
