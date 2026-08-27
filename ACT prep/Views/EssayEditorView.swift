//
//  EssayEditorView.swift
//  ACT prep
//
//  Timed 40-minute essay practice with a live word count and autosave, so a
//  draft survives leaving the app mid-session.
//

import SwiftUI
import Combine

/// Persists essay drafts, keyed by prompt id.
final class EssayDrafts {
    static let shared = EssayDrafts()

    private let url: URL
    private var drafts: [String: String]

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("essay_drafts.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            drafts = decoded
        } else {
            drafts = [:]
        }
    }

    func draft(for promptId: String) -> String { drafts[promptId] ?? "" }

    func save(_ text: String, for promptId: String) {
        drafts[promptId] = text
        if let data = try? JSONEncoder().encode(drafts) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func clear(_ promptId: String) {
        drafts[promptId] = nil
        if let data = try? JSONEncoder().encode(drafts) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func reset() {
        drafts = [:]
        try? FileManager.default.removeItem(at: url)
    }
}

struct EssayEditorView: View {
    let prompt: WritingPrompt

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var secondsRemaining = 40 * 60
    @State private var isRunning = true
    @State private var showPrompt = false
    @State private var showExitAlert = false
    @State private var showTimeUp = false
    @State private var startedAt = Date()

    private let totalSeconds = 40 * 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var timeString: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                editor
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(prompt.title)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showExitAlert = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showPrompt = true
                    } label: {
                        Label("Prompt", systemImage: "doc.text")
                    }
                }
            }
            .sheet(isPresented: $showPrompt) { promptSheet }
            .alert("Finish this essay?", isPresented: $showExitAlert) {
                Button("Save & Close") { finish(clearDraft: false) }
                Button("Discard Draft", role: .destructive) { finish(clearDraft: true) }
                Button("Keep Writing", role: .cancel) {}
            } message: {
                Text("Your draft is saved automatically and will be here when you come back.")
            }
            .alert("Time's up", isPresented: $showTimeUp) {
                Button("Keep Writing") { isRunning = false }
                Button("Finish") { finish(clearDraft: false) }
            } message: {
                Text("40 minutes have passed. On test day you'd stop here — \(wordCount) words written.")
            }
        }
        .onAppear {
            text = EssayDrafts.shared.draft(for: prompt.id)
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                isRunning = false
                showTimeUp = true
            }
        }
        .onChange(of: text) { _, newValue in
            EssayDrafts.shared.save(newValue, for: prompt.id)
        }
    }

    private func finish(clearDraft: Bool) {
        if clearDraft {
            EssayDrafts.shared.clear(prompt.id)
        } else {
            EssayDrafts.shared.save(text, for: prompt.id)
        }
        UserSettings.shared.logPractice(seconds: Int(Date().timeIntervalSince(startedAt)))
        dismiss()
    }

    private var statusBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Image(systemName: "timer")
                Text(timeString).monospacedDigit()
            }
            .font(.subheadline.bold())
            .foregroundStyle(secondsRemaining < 300 ? .red : .primary)
            .accessibilityLabel("\(secondsRemaining / 60) minutes remaining")

            ProgressView(value: Double(totalSeconds - secondsRemaining), total: Double(totalSeconds))
                .tint(secondsRemaining < 300 ? .red : .accentColor)

            Text("\(wordCount) words")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                isRunning.toggle()
            } label: {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
            }
            .accessibilityLabel(isRunning ? "Pause timer" : "Resume timer")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(.body)
            .lineSpacing(4)
            .textInputAutocapitalization(.sentences)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(Color.appSecondaryBackground)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Start writing your essay here…")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
    }

    private var promptSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(prompt.context)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(prompt.perspectives) { p in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.label).font(.caption.bold()).foregroundStyle(.tint)
                            Text(p.text).font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .cardBackground(cornerRadius: 12)
                    }
                    Text(prompt.task)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .readableWidth()
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(prompt.title)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { showPrompt = false }
                }
            }
        }
    }
}
