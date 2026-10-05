//
//  LearnView.swift
//  ACT prep
//
//  Hub for everything you read rather than answer: Math & Science tutorials,
//  the Writing section, and the quick-reference rulebook.
//

import SwiftUI

enum LearnRoute: Hashable {
    case tutorials(Subject)
    case writing
    case reference
}

struct LearnView: View {
    @State private var progress = TutorialProgress.shared

    private var library: TutorialLibrary { .shared }
    private var study: StudyLibrary { .shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("Subject Review") {
                        ForEach(library.subjects) { subject in
                            NavigationLink(value: LearnRoute.tutorials(subject)) {
                                tutorialHubCard(subject)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    section("The Essay") {
                        NavigationLink(value: LearnRoute.writing) {
                            hubCard(
                                symbol: "square.and.pencil",
                                title: "Writing",
                                subtitle: "\(study.guides.count) guides · \(study.prompts.count) timed prompts · graded samples",
                                tint: .purple
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    section("Look It Up") {
                        NavigationLink(value: LearnRoute.reference) {
                            hubCard(
                                symbol: "text.book.closed.fill",
                                title: "Quick Reference",
                                subtitle: "\(study.reference.count) rules and formula sheets, searchable",
                                tint: .teal
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .readableWidth(760)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Learn")
            .navigationDestination(for: LearnRoute.self) { route in
                switch route {
                case .tutorials(let subject): TutorialListView(subject: subject)
                case .writing: WritingView()
                case .reference: ReferenceView()
                }
            }
            .navigationDestination(for: Tutorial.self) { TutorialDetailView(tutorial: $0) }
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func tutorialHubCard(_ subject: Subject) -> some View {
        let all = library.tutorials(for: subject)
        let done = progress.completedCount(for: subject)
        let fraction = all.isEmpty ? 0 : Double(done) / Double(all.count)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: subject.symbolName)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(subject.displayName) Tutorials")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(all.count) tutorials · \(done) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.tint)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            ProgressView(value: fraction)
                .tint(fraction >= 1 ? .green : .accentColor)
        }
        .padding(14)
        .cardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func hubCard(symbol: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .cardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Tutorial grid for one subject

struct TutorialListView: View {
    let subject: Subject

    @State private var store = StoreManager.shared
    @State private var progress = TutorialProgress.shared
    @State private var searchText = ""
    @State private var showPaywall = false

    private var library: TutorialLibrary { .shared }

    private var searchResults: [Tutorial] {
        library.search(searchText).filter { $0.subject == subject }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if searchText.isEmpty {
                    ForEach(library.categories(for: subject)) { category in
                        categorySection(category)
                    }
                } else {
                    searchSection
                }
            }
            .padding()
            .readableWidth(900)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("\(subject.displayName) Tutorials")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $searchText, prompt: "Search tutorials")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func categorySection(_ category: TutorialCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.name).font(.title3.bold())
                Spacer()
                Text("\(category.tutorials.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 158), spacing: 12) {
                ForEach(category.tutorials) { tile($0) }
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    .font(.subheadline.bold())
                LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 158), spacing: 12) {
                    ForEach(searchResults) { tile($0) }
                }
            }
        }
    }

    @ViewBuilder
    private func tile(_ tutorial: Tutorial) -> some View {
        let unlocked = store.isTutorialUnlocked(tutorial)
        let done = progress.isCompleted(tutorial.id)

        if unlocked {
            NavigationLink(value: tutorial) {
                tileContent(tutorial, unlocked: true, done: done)
            }
            .buttonStyle(.plain)
        } else {
            Button { showPaywall = true } label: {
                tileContent(tutorial, unlocked: false, done: done)
            }
            .buttonStyle(.plain)
        }
    }

    private func tileContent(_ tutorial: Tutorial, unlocked: Bool, done: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(unlocked ? Color.accentColor.opacity(0.15) : Color.appFill)
                        .frame(width: 42, height: 42)
                    Image(systemName: unlocked ? tutorial.symbolName : "lock.fill")
                        .font(.title3)
                        .foregroundStyle(unlocked ? Color.accentColor : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                Spacer()
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
            }

            Text(tutorial.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(tutorial.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("\(tutorial.estimatedMinutes) min")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
        .cardBackground(cornerRadius: Layout.tileCorner)
        .contentShape(RoundedRectangle(cornerRadius: Layout.tileCorner))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(tutorial.title). \(tutorial.summary) \(tutorial.estimatedMinutes) minutes."
                + (unlocked ? (done ? " Completed." : "") : " Locked, requires Pro.")
        )
        .accessibilityAddTraits(.isButton)
    }
}
