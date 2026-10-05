//
//  StudyContent.swift
//  ACT prep
//
//  Flashcards, the quick-reference rulebook, and the Writing (optional essay)
//  content. All bundled as JSON and decoded at launch.
//

import Foundation

// MARK: - Flashcards

struct Flashcard: Codable, Identifiable, Hashable {
    let id: String
    let subject: Subject
    let deck: String
    let front: String
    let back: String
    let hint: String
}

struct FlashcardDeck: Identifiable, Hashable {
    let name: String
    let subject: Subject
    let cards: [Flashcard]
    var id: String { name }

    var symbolName: String {
        switch name {
        case "Grammar Rules": return "textformat.abc"
        case "Punctuation": return "quote.opening"
        case "Math Formulas": return "function"
        case "Science Terms": return "atom"
        case "Vocabulary in Context": return "character.book.closed.fill"
        default: return subject.symbolName
        }
    }
}

// MARK: - Quick reference

struct ReferenceExample: Codable, Hashable {
    let wrong: String
    let right: String
    let why: String
}

struct ReferenceEntry: Codable, Identifiable, Hashable {
    let id: String
    let subject: Subject
    let category: String
    let title: String
    let summary: String
    let body: String
    let examples: [ReferenceExample]
    let trap: String
}

// MARK: - Writing

struct WritingPerspective: Codable, Hashable, Identifiable {
    let label: String
    let text: String
    var id: String { label }
}

struct WritingPrompt: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let context: String
    let perspectives: [WritingPerspective]
    let task: String
}

struct GraderComments: Codable, Hashable {
    let ideasAndAnalysis: String
    let developmentAndSupport: String
    let organization: String
    let languageUse: String

    var rows: [(String, String)] {
        [("Ideas & Analysis", ideasAndAnalysis),
         ("Development & Support", developmentAndSupport),
         ("Organization", organization),
         ("Language Use", languageUse)]
    }
}

struct SampleEssay: Codable, Identifiable, Hashable {
    let id: String
    let promptId: String
    let score: Int
    let label: String
    let essay: String
    let graderComments: GraderComments
}

struct WritingGuide: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String
    let summary: String
    let estimatedMinutes: Int
    let sections: [TutorialSection]
    let checklist: [String]
}

// MARK: - Library

final class StudyLibrary {
    static let shared = StudyLibrary()

    private(set) var flashcards: [Flashcard] = []
    private(set) var reference: [ReferenceEntry] = []
    private(set) var prompts: [WritingPrompt] = []
    private(set) var samples: [SampleEssay] = []
    private(set) var guides: [WritingGuide] = []

    private init() {
        flashcards = Self.load("flashcards")
        reference = Self.load("reference")
        prompts = Self.load("writing_prompts")
        samples = Self.load("writing_samples")
        guides = Self.load("writing_guides")
    }

    private static func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return items
    }

    /// Decks in the order they appear in the JSON.
    var decks: [FlashcardDeck] {
        var order: [String] = []
        var grouped: [String: [Flashcard]] = [:]
        for card in flashcards {
            if grouped[card.deck] == nil { order.append(card.deck) }
            grouped[card.deck, default: []].append(card)
        }
        return order.compactMap { name in
            guard let cards = grouped[name], let first = cards.first else { return nil }
            return FlashcardDeck(name: name, subject: first.subject, cards: cards)
        }
    }

    func deck(named name: String) -> FlashcardDeck? {
        decks.first { $0.name == name }
    }

    /// Reference categories in JSON order.
    var referenceCategories: [String] {
        var order: [String] = []
        for entry in reference where !order.contains(entry.category) {
            order.append(entry.category)
        }
        return order
    }

    func reference(in category: String) -> [ReferenceEntry] {
        reference.filter { $0.category == category }
    }

    func searchReference(_ query: String) -> [ReferenceEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return reference.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.summary.localizedCaseInsensitiveContains(q)
                || $0.body.localizedCaseInsensitiveContains(q)
                || $0.category.localizedCaseInsensitiveContains(q)
        }
    }

    func prompt(id: String) -> WritingPrompt? { prompts.first { $0.id == id } }

    func samples(for promptId: String) -> [SampleEssay] {
        samples.filter { $0.promptId == promptId }.sorted { $0.score > $1.score }
    }

    /// Prompts that have at least one graded sample essay attached.
    var promptsWithSamples: Set<String> { Set(samples.map(\.promptId)) }
}
