//
//  MockExamsView.swift
//  ACT prep
//
//  Pushed from the Practice tab. Lists the 15 mock exams and lets the student
//  choose Quick or Full-Length timing.
//

import SwiftUI

struct MockExamsView: View {
    @State private var store = StoreManager.shared
    @State private var progress = ProgressStore.shared
    @State private var selectedExam: MockExam?
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                ForEach(MockExam.all) { exam in
                    examRow(exam)
                }
            } header: {
                Text("15 Mock Exams")
            } footer: {
                Text("Quick: 47 questions in 44 minutes. Full-Length: 171 questions in 2 hours 45 minutes, matching real ACT section timing.")
            }
        }
        .navigationTitle("Mock Exams")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $selectedExam) { exam in
            ExamModeSheet(exam: exam)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func examRow(_ exam: MockExam) -> some View {
        let unlocked = store.isExamUnlocked(exam)
        let best = progress.examResults
            .filter { $0.examNumber == exam.number }
            .map(\.composite)
            .max()

        return Button {
            if unlocked {
                selectedExam = exam
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(unlocked ? Color.accentColor.opacity(0.15) : Color.appFill)
                        .frame(width: 44, height: 44)
                    if unlocked {
                        Text("\(exam.number)")
                            .font(.headline)
                            .foregroundStyle(.tint)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(exam.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let best {
                        Text("Best composite: \(best)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(exam.isFree ? "Free" : "Pro")
                            .font(.caption)
                            .foregroundStyle(exam.isFree ? .green : .secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .tint(.primary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(exam.title). " + (unlocked
                ? (best.map { "Best composite \($0)." } ?? "Not attempted.")
                : "Locked, requires Pro.")
        )
    }
}

// MARK: - Mode chooser

struct ExamModeSheet: View {
    let exam: MockExam
    @Environment(\.dismiss) private var dismiss
    @State private var runningMode: ExamMode?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ForEach(ExamMode.allCases) { mode in
                    modeCard(mode)
                }
                Spacer()
            }
            .padding()
            .readableWidth(560)
            .navigationTitle(exam.title)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(item: $runningMode) { mode in
                ExamRunnerView(exam: exam, mode: mode)
            }
            .onChange(of: runningMode) { old, new in
                // Close the chooser once the exam itself has been dismissed.
                if old != nil && new == nil { dismiss() }
            }
        }
    }

    private func modeCard(_ mode: ExamMode) -> some View {
        Button {
            runningMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        mode.displayName,
                        systemImage: mode == .quick ? "bolt.fill" : "clock.fill"
                    )
                    .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text(description(mode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func description(_ mode: ExamMode) -> String {
        let q = exam.totalQuestions(mode: mode)
        let m = exam.totalMinutes(mode: mode)
        let h = m / 60, rem = m % 60
        let time = h > 0 ? "\(h) hr \(rem) min" : "\(m) min"
        switch mode {
        case .quick:
            return "\(q) questions · \(time). A condensed run through all four sections."
        case .full:
            return "\(q) questions · \(time). Real ACT structure and timing: English, Math, Reading, Science."
        }
    }
}
