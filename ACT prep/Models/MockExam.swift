//
//  MockExam.swift
//  ACT prep
//

import Foundation

enum ExamMode: String, Codable, CaseIterable, Identifiable {
    case quick, full
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quick: return "Quick"
        case .full: return "Full-Length"
        }
    }

    func count(for subject: Subject) -> Int {
        self == .full ? subject.fullCount : subject.quickCount
    }

    func minutes(for subject: Subject) -> Int {
        self == .full ? subject.fullMinutes : subject.quickMinutes
    }
}

struct MockExam: Identifiable, Hashable {
    let index: Int          // 0-based
    var id: Int { index }
    var number: Int { index + 1 }
    var title: String { "Mock Exam \(number)" }

    /// The first two mock exams are free; the rest require Pro.
    var isFree: Bool { index < 2 }

    static let all: [MockExam] = (0..<15).map(MockExam.init)

    func totalMinutes(mode: ExamMode) -> Int {
        Subject.allCases.reduce(0) { $0 + mode.minutes(for: $1) }
    }

    func totalQuestions(mode: ExamMode) -> Int {
        Subject.allCases.reduce(0) { $0 + mode.count(for: $1) }
    }
}

// MARK: - Results

struct SectionResult: Codable, Identifiable, Hashable {
    let subject: Subject
    let correct: Int
    let total: Int
    var id: String { subject.rawValue }
    var scaled: Int { ACTScoring.scaledScore(correct: correct, total: total) }
}

struct ExamResult: Codable, Identifiable, Hashable {
    let id: UUID
    let examNumber: Int
    let mode: ExamMode
    let date: Date
    let sections: [SectionResult]

    var composite: Int { ACTScoring.composite(sections.map(\.scaled)) }
    var totalCorrect: Int { sections.map(\.correct).reduce(0, +) }
    var totalQuestions: Int { sections.map(\.total).reduce(0, +) }
}
