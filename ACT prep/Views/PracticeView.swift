//
//  PracticeView.swift
//  ACT prep
//
//  Hosts both question practice (by subject/topic) and the 15 mock exams.
//

import SwiftUI

struct PracticeView: View {
    @State private var store = StoreManager.shared
    @State private var progress = ProgressStore.shared

    @State private var settings = UserSettings.shared
    @State private var scheduler = FlashcardScheduler.shared

    private enum Route: Hashable {
        case subject(Subject)
        case mockExams
        case diagnostic
        case flashcards
    }

    var body: some View {
        NavigationStack {
            List {
                if !settings.hasTakenDiagnostic {
                    Section {
                        NavigationLink(value: Route.diagnostic) {
                            diagnosticRow
                        }
                    } header: {
                        Text("Start Here")
                    } footer: {
                        Text("A short placement test that finds your starting score and your weakest topics.")
                    }
                }

                Section {
                    NavigationLink(value: Route.mockExams) {
                        mockExamRow
                    }
                    NavigationLink(value: Route.flashcards) {
                        flashcardRow
                    }
                    if settings.hasTakenDiagnostic {
                        NavigationLink(value: Route.diagnostic) {
                            Label("Retake Diagnostic", systemImage: "stethoscope")
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Drills")
                } footer: {
                    Text("Quick: 47 questions in 44 minutes. Full-Length: real ACT timing.")
                }

                Section {
                    ForEach(Subject.allCases) { subject in
                        NavigationLink(value: Route.subject(subject)) {
                            subjectRow(subject)
                        }
                    }
                } header: {
                    Text("Practice by Subject")
                } footer: {
                    if !store.isPro {
                        Text("The free plan includes the first \(StoreManager.freePracticeLimit) questions in each subject. Subscribe for all 520.")
                    }
                }
            }
            .navigationTitle("Practice")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .subject(let subject): PracticeSetupView(subject: subject)
                case .mockExams: MockExamsView()
                case .diagnostic: DiagnosticIntroView()
                case .flashcards: FlashcardsView()
                }
            }
        }
    }

    private var diagnosticRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: "stethoscope")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Take the Diagnostic")
                    .font(.headline)
                Text("Find your baseline score in about 35 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var flashcardRow: some View {
        let due = scheduler.totalDue
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Flashcards")
                    .font(.headline)
                Text("\(StudyLibrary.shared.flashcards.count) cards · spaced repetition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if due > 0 {
                TagPill(text: "\(due) due", tint: .orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var mockExamRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Take a Mock Exam")
                    .font(.headline)
                Text("15 exams · Quick or Full-Length")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let best = progress.bestComposite {
                VStack(spacing: 1) {
                    Text("\(best)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.tint)
                    Text("best")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func subjectRow(_ subject: Subject) -> some View {
        let stats = progress.practiceStats(for: subject)
        let total = QuestionBank.shared.questions(for: subject).count
        return HStack(spacing: 14) {
            Image(systemName: subject.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(subject.displayName)
                    .font(.headline)
                Text("\(total) questions · \(stats.attempted) attempted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if stats.attempted > 0 {
                Text("\(Int((Double(stats.correct) / Double(max(stats.attempted, 1)) * 100).rounded()))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Setup (topic filter)

struct PracticeSetupView: View {
    let subject: Subject
    @State private var selectedTopic: String?
    @State private var startSession = false

    private var topics: [String] { QuestionBank.shared.topics(for: subject) }

    private var questionCount: Int {
        let all = QuestionBank.shared.questions(for: subject)
        guard let topic = selectedTopic else { return all.count }
        return all.filter { $0.topic == topic }.count
    }

    var body: some View {
        List {
            Section("Topic") {
                topicRow(nil, label: "All Topics")
                ForEach(topics, id: \.self) { topic in
                    topicRow(topic, label: topic)
                }
            }
            Section {
                Button {
                    startSession = true
                } label: {
                    Label("Start Practice (\(questionCount) questions)", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(questionCount == 0)
            }
        }
        .navigationTitle(subject.displayName)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fullScreenCover(isPresented: $startSession) {
            PracticeSessionView(subject: subject, topic: selectedTopic)
        }
    }

    private func topicRow(_ topic: String?, label: String) -> some View {
        Button {
            selectedTopic = topic
        } label: {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                if selectedTopic == topic {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTopic == topic ? .isSelected : [])
    }
}

// MARK: - Session

struct PracticeSessionView: View {
    let subject: Subject
    let topic: String?

    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreManager.shared
    @State private var index = 0
    @State private var selected: Int?
    @State private var showPaywall = false
    @State private var sessionCorrect = 0
    @State private var sessionAnswered = 0
    @State private var startedAt = Date()
    @State private var eliminated: Set<Int> = []
    @State private var usedHint = false

    private var questions: [Question] {
        let all = QuestionBank.shared.questions(for: subject)
        guard let topic else { return all }
        return all.filter { $0.topic == topic }
    }

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    ContentUnavailableView(
                        "No Questions",
                        systemImage: "tray",
                        description: Text("Question content hasn't been loaded.")
                    )
                } else if !store.isPracticeQuestionUnlocked(index: index) {
                    lockedView
                } else {
                    questionView
                }
            }
            .navigationTitle("\(index + 1) of \(questions.count)")
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { endSession() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if sessionAnswered > 0 {
                        Text("\(sessionCorrect)/\(sessionAnswered)")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(sessionCorrect) correct of \(sessionAnswered) answered")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func endSession() {
        UserSettings.shared.logPractice(seconds: Int(Date().timeIntervalSince(startedAt)))
        dismiss()
    }

    private var questionView: some View {
        let question = questions[index]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let passage = QuestionBank.shared.passage(for: question) {
                    PassageBox(passage: passage)
                }
                QuestionCard(
                    question: question,
                    selectedIndex: selected,
                    showFeedback: true,
                    eliminated: eliminated
                ) { choice in
                    guard selected == nil else { return }
                    selected = choice
                    sessionAnswered += 1
                    let correct = choice == question.correctIndex
                    if correct { sessionCorrect += 1 }
                    ProgressStore.shared.recordPractice(questionId: question.id, correct: correct)
                }
            }
            .padding()
            .readableWidth()
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    goTo(index - 1)
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(index == 0)

                Spacer()

                if selected == nil {
                    Button {
                        narrowDown(question)
                    } label: {
                        Label(usedHint ? "Hint used" : "Narrow it down", systemImage: "lightbulb")
                    }
                    .buttonStyle(.bordered)
                    .disabled(usedHint)
                }

                Button {
                    goTo(index + 1)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.trailingIcon)
                }
                .buttonStyle(.borderedProminent)
                .disabled(index >= questions.count - 1)
            }
            .padding()
            .background(.bar)
        }
    }

    /// Rules out one wrong answer, so a stuck student gets a nudge rather than
    /// the answer.
    private func narrowDown(_ question: Question) {
        let wrong = question.choices.indices.filter {
            $0 != question.correctIndex && !eliminated.contains($0)
        }
        guard let toRemove = wrong.randomElement() else { return }
        withAnimation(.snappy) {
            eliminated.insert(toRemove)
            usedHint = true
        }
    }

    private var lockedView: some View {
        ContentUnavailableView {
            Label("Subscribe to Continue", systemImage: "lock.fill")
        } description: {
            Text("You've finished the \(StoreManager.freePracticeLimit) free questions in \(subject.displayName). ACT Prep Pro unlocks all 520 questions, 40 tutorials, and 15 mock exams.")
        } actions: {
            Button("See Plans") { showPaywall = true }
                .buttonStyle(.borderedProminent)
            Button("Back") { goTo(index - 1) }
        }
    }

    private func goTo(_ newIndex: Int) {
        guard questions.indices.contains(newIndex) else { return }
        index = newIndex
        selected = nil
        eliminated = []
        usedHint = false
    }
}
