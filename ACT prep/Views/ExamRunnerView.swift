//
//  ExamRunnerView.swift
//  ACT prep
//

import SwiftUI

struct ExamRunnerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var session: ExamSession
    @State private var showQuestionGrid = false
    @State private var showEndSectionAlert = false
    @State private var showQuitAlert = false
    @State private var savedResult: ExamResult?

    init(exam: MockExam, mode: ExamMode) {
        _session = State(initialValue: ExamSession(exam: exam, mode: mode))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let result = savedResult {
                    ExamResultView(result: result) { dismiss() }
                } else {
                    sectionView
                }
            }
        }
        .interactiveDismissDisabled(savedResult == nil)
        .onChange(of: session.isFinished) { _, finished in
            if finished && savedResult == nil {
                let result = session.result()
                ProgressStore.shared.save(result: result)
                UserSettings.shared.logPractice(seconds: session.elapsedSeconds)
                savedResult = result
            }
        }
    }

    // MARK: Section / question UI

    private var sectionView: some View {
        Group {
            if let question = session.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader
                        if let passage = QuestionBank.shared.passage(for: question) {
                            PassageBox(passage: passage)
                        }
                        QuestionCard(
                            question: question,
                            selectedIndex: session.selectedChoice(),
                            showFeedback: false
                        ) { choice in
                            session.select(choice: choice)
                        }
                    }
                    .padding()
                }
                .id(question.id)
                .safeAreaInset(edge: .bottom) { navigationBar }
            } else {
                ContentUnavailableView(
                    "No Questions Loaded",
                    systemImage: "tray",
                    description: Text("Add question content and rebuild.")
                )
            }
        }
        .navigationTitle(session.currentSection.subject.displayName)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Quit", role: .destructive) { showQuitAlert = true }
            }
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text(session.timeString)
                        .monospacedDigit()
                }
                .font(.subheadline.bold())
                .foregroundStyle(session.secondsRemaining < 60 ? .red : .primary)
            }
        }
        .alert("End this section?", isPresented: $showEndSectionAlert) {
            Button(session.isLastSection ? "Finish Exam" : "End Section", role: .destructive) {
                session.endSection()
            }
            Button("Keep Working", role: .cancel) {}
        } message: {
            let unanswered = session.currentSection.questions.count - session.answeredInCurrentSection
            Text(unanswered > 0
                 ? "You have \(unanswered) unanswered question\(unanswered == 1 ? "" : "s") in this section."
                 : "All questions answered.")
        }
        .alert("Quit exam?", isPresented: $showQuitAlert) {
            Button("Quit Without Saving", role: .destructive) { dismiss() }
            Button("Keep Working", role: .cancel) {}
        } message: {
            Text("Your progress in this exam will be lost.")
        }
        .sheet(isPresented: $showQuestionGrid) { questionGrid }
    }

    private var sectionHeader: some View {
        HStack {
            Text("Section \(session.sections.firstIndex(where: { $0.subject == session.currentSection.subject }).map { $0 + 1 } ?? 1) of \(session.sections.count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                showQuestionGrid = true
            } label: {
                Label(
                    "Question \(session.questionIndex + 1) of \(session.currentSection.questions.count)",
                    systemImage: "square.grid.3x3.fill"
                )
                .font(.caption.bold())
            }
        }
    }

    private var navigationBar: some View {
        HStack {
            Button {
                session.goToPrevious()
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(session.questionIndex == 0)

            Spacer()

            if session.isLastQuestionInSection {
                Button {
                    showEndSectionAlert = true
                } label: {
                    Label(
                        session.isLastSection ? "Finish Exam" : "End Section",
                        systemImage: "flag.checkered"
                    )
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    session.goToNext()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.trailingIcon)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.bar)
    }

    private var questionGrid: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(session.currentSection.questions.indices, id: \.self) { i in
                        let q = session.currentSection.questions[i]
                        let answered = session.answers[q.id] != nil
                        Button {
                            session.jump(to: i)
                            showQuestionGrid = false
                        } label: {
                            Text("\(i + 1)")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    answered ? Color.accentColor : Color(.tertiarySystemFill),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .foregroundStyle(answered ? .white : .primary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Questions")
            #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { showQuestionGrid = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Results

struct ExamResultView: View {
    let result: ExamResult
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Composite Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(result.composite)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.tint)
                    Text("out of 36")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(result.sections) { section in
                        HStack {
                            Label(section.subject.displayName, systemImage: section.subject.symbolName)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(section.correct)/\(section.total)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(section.scaled)")
                                .font(.headline)
                                .frame(width: 44, height: 32)
                                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text("\(result.totalCorrect) of \(result.totalQuestions) questions correct · \(result.mode.displayName) mode")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Mock Exam \(result.examNumber)")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
