//
//  Tutorial.swift
//  ACT prep
//

import Foundation
import Observation

struct TutorialSection: Codable, Hashable {
    let heading: String
    let body: String
}

struct WorkedExample: Codable, Hashable, Identifiable {
    let problem: String
    let steps: [String]
    let answer: String
    var id: String { problem }
}

struct Tutorial: Codable, Identifiable, Hashable {
    let id: String
    let subject: Subject
    let category: String
    let title: String
    let symbolName: String
    let summary: String
    let estimatedMinutes: Int
    let sections: [TutorialSection]
    let keyFacts: [String]
    let examples: [WorkedExample]
    let tips: [String]
}

/// A category of tutorials for one subject, used to build the grid sections.
struct TutorialCategory: Identifiable, Hashable {
    let subject: Subject
    let name: String
    let tutorials: [Tutorial]
    var id: String { "\(subject.rawValue)-\(name)" }
}

final class TutorialLibrary {
    static let shared = TutorialLibrary()

    private(set) var tutorials: [Tutorial] = []

    private init() {
        let decoder = JSONDecoder()
        for name in ["math_tutorials", "science_tutorials"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let items = try? decoder.decode([Tutorial].self, from: data) else { continue }
            tutorials.append(contentsOf: items)
        }
    }

    /// Subjects that have tutorial content, in display order.
    var subjects: [Subject] {
        [Subject.math, Subject.science].filter { subject in
            tutorials.contains { $0.subject == subject }
        }
    }

    func tutorials(for subject: Subject) -> [Tutorial] {
        tutorials.filter { $0.subject == subject }
    }

    /// Tutorials grouped into categories, preserving the order they appear in
    /// the JSON so the authored sequence drives the UI.
    func categories(for subject: Subject) -> [TutorialCategory] {
        var order: [String] = []
        var grouped: [String: [Tutorial]] = [:]
        for tutorial in tutorials(for: subject) {
            if grouped[tutorial.category] == nil { order.append(tutorial.category) }
            grouped[tutorial.category, default: []].append(tutorial)
        }
        return order.map { TutorialCategory(subject: subject, name: $0, tutorials: grouped[$0] ?? []) }
    }

    func tutorial(id: String) -> Tutorial? {
        tutorials.first { $0.id == id }
    }

    func search(_ query: String) -> [Tutorial] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return tutorials.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.category.localizedCaseInsensitiveContains(trimmed)
                || $0.summary.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

/// Tracks which tutorials the student has marked as read.
@Observable
final class TutorialProgress {
    static let shared = TutorialProgress()

    private let key = "completedTutorials"
    private(set) var completed: Set<String>

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        completed = Set(stored)
    }

    func isCompleted(_ id: String) -> Bool { completed.contains(id) }

    func toggle(_ id: String) {
        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
        UserDefaults.standard.set(Array(completed), forKey: key)
    }

    func completedCount(for subject: Subject) -> Int {
        TutorialLibrary.shared.tutorials(for: subject).filter { completed.contains($0.id) }.count
    }

    func reset() {
        completed = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}
