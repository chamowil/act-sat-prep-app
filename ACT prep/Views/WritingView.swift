//
//  WritingView.swift
//  ACT prep
//
//  The optional ACT Writing section: how-to guides, timed practice against real
//  three-perspective prompts, and scored sample essays with grader comments.
//

import SwiftUI

struct WritingView: View {
    @State private var store = StoreManager.shared
    @State private var showPaywall = false

    private var library: StudyLibrary { .shared }

    var body: some View {
        List {
            Section {
                ForEach(library.guides) { guide in
                    NavigationLink(value: guide) {
                        guideRow(guide)
                    }
                }
            } header: {
                Text("Learn the Essay")
            } footer: {
                Text("The ACT essay is optional and scored 2–12 by two graders. Check whether the colleges you're applying to require it.")
            }

            Section("Practice Prompts") {
                ForEach(library.prompts) { prompt in
                    promptRow(prompt)
                }
            }
        }
        .navigationTitle("Writing")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(for: WritingGuide.self) { WritingGuideView(guide: $0) }
        .navigationDestination(for: WritingPrompt.self) { WritingPromptView(prompt: $0) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func guideRow(_ guide: WritingGuide) -> some View {
        HStack(spacing: 12) {
            Image(systemName: guide.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(guide.title).font(.subheadline.weight(.medium))
                Text(guide.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text("\(guide.estimatedMinutes)m")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func promptRow(_ prompt: WritingPrompt) -> some View {
        let unlocked = store.isPro || library.prompts.firstIndex(of: prompt) == 0
        let hasSamples = library.promptsWithSamples.contains(prompt.id)

        if unlocked {
            NavigationLink(value: prompt) { promptContent(prompt, locked: false, hasSamples: hasSamples) }
        } else {
            Button { showPaywall = true } label: {
                promptContent(prompt, locked: true, hasSamples: hasSamples)
            }
            .buttonStyle(.plain)
        }
    }

    private func promptContent(_ prompt: WritingPrompt, locked: Bool, hasSamples: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: locked ? "lock.fill" : "square.and.pencil")
                .font(.subheadline)
                .foregroundStyle(locked ? .secondary : Color.accentColor)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(prompt.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(hasSamples ? "3 perspectives · graded samples included" : "3 perspectives · 40 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

// MARK: - Guide

struct WritingGuideView: View {
    let guide: WritingGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: guide.symbolName)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor.opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(guide.title).font(.title3.bold())
                            TagPill(text: "\(guide.estimatedMinutes) min", symbol: "clock", tint: .secondary)
                        }
                    }
                    Text(guide.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                ForEach(Array(guide.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading).font(.headline)
                        Text(section.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .cardBackground()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Checklist", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(.tint)
                    ForEach(Array(guide.checklist.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(.tint)
                                .padding(.top, 7)
                                .accessibilityHidden(true)
                            Text(item)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()
            }
            .padding()
            .readableWidth()
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Guide")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Prompt

struct WritingPromptView: View {
    let prompt: WritingPrompt
    @State private var isWriting = false

    private var samples: [SampleEssay] { StudyLibrary.shared.samples(for: prompt.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(prompt.title).font(.title3.bold())
                    Text(prompt.context)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Perspectives").font(.headline)
                    ForEach(prompt.perspectives) { p in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(p.label)
                                .font(.caption.bold())
                                .foregroundStyle(.tint)
                            Text(p.text)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.appGroupedBackground,
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Task", systemImage: "pencil.line")
                        .font(.headline)
                        .foregroundStyle(.tint)
                    Text(prompt.task)
                        .font(.subheadline)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                Button {
                    isWriting = true
                } label: {
                    Label("Start Timed Essay (40 min)", systemImage: "timer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                if !samples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Scored Samples").font(.headline)
                        Text("Read these after you write, not before.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(samples) { sample in
                            NavigationLink(value: sample) {
                                HStack(spacing: 12) {
                                    Text("\(sample.score)")
                                        .font(.headline.monospacedDigit())
                                        .frame(width: 36, height: 36)
                                        .background(scoreTint(sample.score).opacity(0.18), in: Circle())
                                        .foregroundStyle(scoreTint(sample.score))
                                    Text(sample.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(12)
                                .background(Color.appGroupedBackground,
                                            in: RoundedRectangle(cornerRadius: 12))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .cardBackground()
                }
            }
            .padding()
            .readableWidth()
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Prompt")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(for: SampleEssay.self) { SampleEssayView(sample: $0) }
        .fullScreenCover(isPresented: $isWriting) {
            EssayEditorView(prompt: prompt)
        }
    }

    private func scoreTint(_ score: Int) -> Color {
        switch score {
        case 6: return .green
        case 5: return .teal
        case 4: return .blue
        case 3: return .orange
        default: return .red
        }
    }
}

// MARK: - Sample essay

struct SampleEssayView: View {
    let sample: SampleEssay

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Text("\(sample.score)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(sample.label).font(.headline)
                        Text("out of 6 per domain")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                VStack(alignment: .leading, spacing: 8) {
                    Text("The Essay").font(.headline)
                    Text(sample.essay)
                        .font(.callout)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                VStack(alignment: .leading, spacing: 14) {
                    Label("Grader Comments", systemImage: "text.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(.tint)
                    ForEach(sample.graderComments.rows, id: \.0) { title, text in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(text)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()
            }
            .padding()
            .readableWidth()
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Sample Essay")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
