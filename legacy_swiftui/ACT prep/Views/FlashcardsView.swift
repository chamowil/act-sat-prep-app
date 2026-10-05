//
//  FlashcardsView.swift
//  ACT prep
//

import SwiftUI

struct FlashcardsView: View {
    @State private var scheduler = FlashcardScheduler.shared
    @State private var store = StoreManager.shared
    @State private var activeDeck: FlashcardDeck?
    @State private var showPaywall = false

    private var decks: [FlashcardDeck] { StudyLibrary.shared.decks }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary
                LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 240), spacing: 12) {
                    ForEach(decks) { deck in
                        deckCard(deck)
                    }
                }
            }
            .padding()
            .readableWidth(860)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Flashcards")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fullScreenCover(item: $activeDeck) { deck in
            FlashcardSessionView(deck: deck)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var summary: some View {
        let total = StudyLibrary.shared.flashcards.count
        let learned = scheduler.totalLearned
        return HStack(spacing: 0) {
            stat("\(scheduler.totalDue)", "due now")
            Divider().frame(height: 38)
            stat("\(learned)", "learned")
            Divider().frame(height: 38)
            stat("\(total)", "total cards")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func deckCard(_ deck: FlashcardDeck) -> some View {
        let due = scheduler.dueCount(in: deck)
        let learned = scheduler.learnedCount(in: deck)
        let unlocked = store.isPro || deck.subject == .english
        let fraction = deck.cards.isEmpty ? 0 : Double(learned) / Double(deck.cards.count)

        return Button {
            if unlocked { activeDeck = deck } else { showPaywall = true }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: unlocked ? deck.symbolName : "lock.fill")
                        .font(.title3)
                        .foregroundStyle(unlocked ? Color.accentColor : .secondary)
                        .frame(width: 38, height: 38)
                        .background(unlocked ? Color.accentColor.opacity(0.15) : Color.appFill,
                                    in: RoundedRectangle(cornerRadius: 9))
                    Spacer()
                    if unlocked && due > 0 {
                        TagPill(text: "\(due) due", tint: .orange)
                    }
                }
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text("\(learned) of \(deck.cards.count) learned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: fraction)
                    .tint(fraction >= 1 ? .green : .accentColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground(cornerRadius: Layout.tileCorner)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(deck.name). \(learned) of \(deck.cards.count) learned."
            + (unlocked ? (due > 0 ? " \(due) due for review." : "") : " Locked, requires Pro.")
        )
    }
}

// MARK: - Session

struct FlashcardSessionView: View {
    let deck: FlashcardDeck

    @Environment(\.dismiss) private var dismiss
    @State private var scheduler = FlashcardScheduler.shared
    @State private var queue: [Flashcard] = []
    @State private var index = 0
    @State private var isFlipped = false
    @State private var showHint = false
    @State private var reviewed = 0
    @State private var startedAt = Date()

    private var card: Flashcard? { queue.indices.contains(index) ? queue[index] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if let card {
                    session(card)
                } else {
                    finished
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(deck.name)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { finish() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !queue.isEmpty {
                        Text("\(min(index + 1, queue.count)) / \(queue.count)")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if queue.isEmpty {
                queue = scheduler.dueCards(in: deck)
                // Nothing due: offer a light refresher rather than an empty screen.
                if queue.isEmpty { queue = Array(deck.cards.prefix(10)) }
            }
        }
    }

    private func finish() {
        UserSettings.shared.logPractice(seconds: Int(Date().timeIntervalSince(startedAt)))
        dismiss()
    }

    private func session(_ card: Flashcard) -> some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 14) {
                    cardFace(card)
                    if showHint && !isFlipped {
                        Label(card.hint, systemImage: "lightbulb.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .cardBackground(cornerRadius: 12)
                            .transition(.opacity)
                    }
                }
                .padding()
                .readableWidth(600)
            }

            controls(card)
                .padding()
                .readableWidth(600)
        }
    }

    private func cardFace(_ card: Flashcard) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TagPill(text: isFlipped ? "Answer" : "Question",
                    symbol: isFlipped ? "checkmark.circle" : "questionmark.circle")
            Text(isFlipped ? card.back : card.front)
                .font(isFlipped ? .body : .title3.weight(.semibold))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isFlipped {
                Divider()
                Text(card.front)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .cardBackground()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) { isFlipped.toggle() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isFlipped ? "Double tap to see the question" : "Double tap to reveal the answer")
    }

    @ViewBuilder
    private func controls(_ card: Flashcard) -> some View {
        if isFlipped {
            VStack(spacing: 8) {
                Text("How well did you know it?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(RecallGrade.allCases) { grade in
                        Button {
                            grade1(card, grade)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: grade.symbolName)
                                Text(grade.title).font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(tint(for: grade).opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(tint(for: grade))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(grade.title)
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.snappy) { showHint = true }
                } label: {
                    Label("Hint", systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(showHint)

                Button {
                    withAnimation(.snappy) { isFlipped = true }
                } label: {
                    Label("Show Answer", systemImage: "arrow.2.squarepath")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func tint(for grade: RecallGrade) -> Color {
        switch grade {
        case .forgot: return .red
        case .hard: return .orange
        case .good: return .blue
        case .easy: return .green
        }
    }

    private func grade1(_ card: Flashcard, _ grade: RecallGrade) {
        scheduler.record(cardId: card.id, grade: grade)
        reviewed += 1
        withAnimation(.snappy) {
            isFlipped = false
            showHint = false
            index += 1
        }
    }

    private var finished: some View {
        ContentUnavailableView {
            Label("Session Complete", systemImage: "checkmark.circle.fill")
        } description: {
            Text(reviewed > 0
                 ? "You reviewed \(reviewed) card\(reviewed == 1 ? "" : "s"). Cards you found hard will come back sooner."
                 : "No cards are due in this deck right now.")
        } actions: {
            Button("Done") { finish() }
                .buttonStyle(.borderedProminent)
        }
    }
}
