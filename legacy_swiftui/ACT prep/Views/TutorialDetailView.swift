//
//  TutorialDetailView.swift
//  ACT prep
//

import SwiftUI

struct TutorialDetailView: View {
    let tutorial: Tutorial

    @State private var progress = TutorialProgress.shared
    @State private var revealedExamples: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                ForEach(Array(tutorial.sections.enumerated()), id: \.offset) { _, section in
                    sectionBlock(section)
                }
                if !tutorial.keyFacts.isEmpty { keyFactsBlock }
                if !tutorial.examples.isEmpty { examplesBlock }
                if !tutorial.tips.isEmpty { tipsBlock }
                completionButton
            }
            .padding()
            .readableWidth()
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(tutorial.title)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    progress.toggle(tutorial.id)
                } label: {
                    Image(systemName: progress.isCompleted(tutorial.id)
                          ? "checkmark.circle.fill" : "circle")
                }
                .accessibilityLabel(progress.isCompleted(tutorial.id)
                                    ? "Mark as not completed" : "Mark as completed")
            }
        }
    }

    // MARK: Blocks

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: tutorial.symbolName)
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(tutorial.title)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        TagPill(text: tutorial.category)
                        TagPill(text: "\(tutorial.estimatedMinutes) min", symbol: "clock", tint: .secondary)
                    }
                }
            }
            Text(tutorial.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private func sectionBlock(_ section: TutorialSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.heading)
                .font(.headline)
            Text(section.body)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private var keyFactsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Key Facts", systemImage: "key.fill")
                .font(.headline)
                .foregroundStyle(.tint)
            ForEach(Array(tutorial.keyFacts.enumerated()), id: \.offset) { _, fact in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(.tint)
                        .padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(fact)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private var examplesBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Worked Examples", systemImage: "pencil.and.outline")
                .font(.headline)
                .foregroundStyle(.tint)

            ForEach(tutorial.examples) { example in
                VStack(alignment: .leading, spacing: 10) {
                    Text(example.problem)
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    if revealedExamples.contains(example.id) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(example.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .frame(width: 20, height: 20)
                                        .background(Color.accentColor.opacity(0.15), in: Circle())
                                        .foregroundStyle(.tint)
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "equal.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Answer: \(example.answer)")
                                    .font(.subheadline.bold())
                            }
                            .padding(.top, 2)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Button {
                            withAnimation(.snappy) {
                                _ = revealedExamples.insert(example.id)
                            }
                        } label: {
                            Label("Show solution", systemImage: "eye.fill")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.appGroupedBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private var tipsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Test-Day Tips", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(Array(tutorial.tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text(tip)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private var completionButton: some View {
        let done = progress.isCompleted(tutorial.id)
        return Button {
            withAnimation(.snappy) { progress.toggle(tutorial.id) }
        } label: {
            Label(
                done ? "Completed" : "Mark as Complete",
                systemImage: done ? "checkmark.circle.fill" : "circle"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(done ? .green : .accentColor)
    }
}
