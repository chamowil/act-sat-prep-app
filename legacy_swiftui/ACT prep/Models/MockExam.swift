//
//  MockExam.swift
//  ACT prep
//

import Foundation

enum ExamMode: String, Codable, CaseIterable, Identifiable {
    case quick, full, diagnostic
    var id: String { rawValue }

    /// Modes a student picks from when starting a mock exam. The diagnostic is
    /// launched from its own entry point, not the mode chooser.
    static var selectable: [ExamMode] { [.quick, .full] }

    var displayName: String {
        switch self {
        case .quick: return "Quick"
        case .full: return "Full-Length"
        case .diagnostic: return "Diagnostic"
        }
    }

    func count(for subject: Subject) -> Int {
        switch self {
        case .full: return subject.fullCount
        case .quick: return subject.quickCount
        case .diagnostic: return subject.diagnosticCount
        }
    }

    func minutes(for subject: Subject) -> Int {
        switch self {
        case .full: return subject.fullMinutes
        case .quick: return subject.quickMinutes
        case .diagnostic: return subject.diagnosticMinutes
        }
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
        UserSettings.shared.activeSubjects.reduce(0) { $0 + mode.minutes(for: $1) }
    }

    func totalQuestions(mode: ExamMode) -> Int {
        UserSettings.shared.activeSubjects.reduce(0) { $0 + mode.count(for: $1) }
    }

    /// The synthetic exam used for the baseline diagnostic.
    static let diagnostic = MockExam(index: 0)
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
