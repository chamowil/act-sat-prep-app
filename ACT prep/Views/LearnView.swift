//
//  LearnView.swift
//  ACT prep
//
//  Math & Science tutorial review, presented as an icon grid grouped by
//  subsection.
//

import SwiftUI

struct LearnView: View {
    @State private var store = StoreManager.shared
    @State private var progress = TutorialProgress.shared
    @State private var subject: Subject = .math
    @State private var searchText = ""
    @State private var showPaywall = false

    private var library: TutorialLibrary { .shared }

    private var searchResults: [Tutorial] {
        library.search(searchText).filter { $0.subject == subject }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    subjectPicker
                    headerCard

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
            .navigationTitle("Tutorials")
            .searchable(text: $searchText, prompt: "Search tutorials")
            .navigationDestination(for: Tutorial.self) { tutorial in
                TutorialDetailView(tutorial: tutorial)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Header

    private var subjectPicker: some View {
        Picker("Subject", selection: $subject.animation(.snappy)) {
            ForEach(library.subjects) { subject in
                Text(subject.displayName).tag(subject)
            }
        }
        .pickerStyle(.segmented)
    }

    private var headerCard: some View {
        let all = library.tutorials(for: subject)
        let done = progress.completedCount(for: subject)
        let fraction = all.isEmpty ? 0 : Double(done) / Double(all.count)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: subject.symbolName)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(subject.displayName) Review")
                        .font(.headline)
                    Text("\(all.count) tutorials · \(done) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.tint)
            }
            ProgressView(value: fraction)
                .tint(.accentColor)
        }
        .padding()
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subject.displayName) review, \(done) of \(all.count) tutorials completed")
    }

    // MARK: Sections

    private func categorySection(_ category: TutorialCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.name)
                    .font(.title3.bold())
                Spacer()
                Text("\(category.tutorials.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 158), spacing: 12) {
                ForEach(category.tutorials) { tutorial in
                    tile(tutorial)
                }
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
                    ForEach(searchResults) { tutorial in
                        tile(tutorial)
                    }
                }
            }
        }
    }

    // MARK: Tile

    @ViewBuilder
    private func tile(_ tutorial: Tutorial) -> some View {
        let unlocked = store.isTutorialUnlocked(tutorial)
        let done = progress.isCompleted(tutorial.id)

        Group {
            if unlocked {
                NavigationLink(value: tutorial) {
                    tileContent(tutorial, unlocked: true, done: done)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    tileContent(tutorial, unlocked: false, done: done)
                }
                .buttonStyle(.plain)
            }
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

#Preview {
    LearnView()
}
