//
//  SettingsView.swift
//  ACT prep
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @State private var store = StoreManager.shared
    @State private var settings = UserSettings.shared
    @State private var showPaywall = false
    @State private var showResetProgressAlert = false
    @State private var showResetAllAlert = false
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false
    @State private var targetScore = Double(UserSettings.shared.targetScore)
    @State private var hasTestDate = UserSettings.shared.testDate != nil
    @State private var testDate = UserSettings.shared.testDate ?? Date()

    private let supportEmail = "support@actprepapp.example"
    private let privacyURL = URL(string: "https://chamowil.github.io/act-prep-support/privacy.html")!
    private let termsURL = URL(string: "https://chamowil.github.io/act-prep-support/terms.html")!
    private let supportURL = URL(string: "https://chamowil.github.io/act-prep-support/")!

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                goalsSection
                scratchpadSection
                studySection
                aboutSection
                dataSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .alert("Reset study progress?", isPresented: $showResetProgressAlert) {
                Button("Reset", role: .destructive) {
                    ProgressStore.shared.resetAll()
                    TutorialProgress.shared.reset()
                    FlashcardScheduler.shared.reset()
                    EssayDrafts.shared.reset()
                    ScratchpadStore.shared.reset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes your exam results, practice history, flashcard schedule, essay drafts, scratchpad notes, and completed tutorials. Your subscription is not affected.")
            }
            .alert("Reset everything?", isPresented: $showResetAllAlert) {
                Button("Reset", role: .destructive) {
                    ProgressStore.shared.resetAll()
                    TutorialProgress.shared.reset()
                    FlashcardScheduler.shared.reset()
                    EssayDrafts.shared.reset()
                    ScratchpadStore.shared.reset()
                    settings.reset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all progress and your study plan, and shows the welcome setup again. Your subscription is not affected.")
            }
        }
    }

    // MARK: Subscription

    private var subscriptionSection: some View {
        Section {
            HStack {
                Label("Plan", systemImage: store.isPro ? "crown.fill" : "person.fill")
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                Text(store.isPro ? "Pro" : "Free")
                    .fontWeight(.semibold)
                    .foregroundStyle(store.isPro ? .green : .secondary)
            }

            if store.isPro {
                Button {
                    showManageSubscriptions = true
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("All \(QuestionBank.shared.formattedCount) questions, \(TutorialLibrary.shared.tutorials.count) tutorials, \(MockExam.all.count) mock exams")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                isRestoring = true
                Task {
                    await store.restorePurchases()
                    isRestoring = false
                }
            } label: {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text("Subscription")
        } footer: {
            if !store.isPro {
                Text("Free plan: \(StoreManager.freePracticeLimit) practice questions per subject, \(StoreManager.freeTutorialLimit) tutorials per subject, and Mock Exam 1.")
            }
        }
    }

    // MARK: Goals

    private var goalsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Target Score", systemImage: "target")
                    Spacer()
                    Text("\(Int(targetScore.rounded()))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.tint)
                }
                Slider(value: $targetScore, in: 1...36, step: 1) {
                    Text("Target score")
                } minimumValueLabel: {
                    Text("1").font(.caption2)
                } maximumValueLabel: {
                    Text("36").font(.caption2)
                }
                .onChange(of: targetScore) { _, newValue in
                    settings.targetScore = Int(newValue.rounded())
                }
                .accessibilityValue("\(Int(targetScore.rounded())) out of 36")
            }
            .padding(.vertical, 4)

            Picker(selection: Binding(
                get: { settings.dailyMinutes },
                set: { settings.dailyMinutes = $0 }
            )) {
                ForEach(UserSettings.dailyMinuteOptions, id: \.self) { minutes in
                    Text("\(minutes) minutes").tag(minutes)
                }
            } label: {
                Label("Daily Goal", systemImage: "clock.badge.checkmark")
            }

            Picker(selection: Binding(
                get: { settings.includesScience },
                set: { settings.includesScience = $0 }
            )) {
                Text("With Science").tag(true)
                Text("Without Science").tag(false)
            } label: {
                Label("Exam Format", systemImage: "atom")
            }

            Toggle(isOn: $hasTestDate.animation(.snappy)) {
                Label("Test Date", systemImage: "calendar")
            }
            .onChange(of: hasTestDate) { _, isOn in
                settings.testDate = isOn ? testDate : nil
            }

            if hasTestDate {
                DatePicker(
                    "Date",
                    selection: $testDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .onChange(of: testDate) { _, newValue in
                    settings.testDate = newValue
                }
            }
        } header: {
            Text("Study Plan")
        } footer: {
            Text("Today: \(settings.minutesPracticedToday) of \(settings.dailyMinutes) minutes. Current streak: \(settings.streak) day\(settings.streak == 1 ? "" : "s").")
        }
    }

    private var scratchpadSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { settings.allowsFingerDrawing },
                set: { settings.allowsFingerDrawing = $0 }
            )) {
                Label("Draw with Finger", systemImage: "hand.draw")
            }
        } header: {
            Text("Scratchpad")
        } footer: {
            Text("Apple Pencil always draws. Turn this off to let a finger scroll the page instead — the usual preference once a Pencil is paired.")
        }
    }

    private var studySection: some View {
        Section("Study") {
            LabeledContent {
                Text("\(QuestionBank.shared.questions.count)")
            } label: {
                Label("Practice questions", systemImage: "list.bullet.rectangle")
            }
            LabeledContent {
                Text("\(TutorialLibrary.shared.tutorials.count)")
            } label: {
                Label("Tutorials", systemImage: "book.fill")
            }
            LabeledContent {
                Text("\(MockExam.all.count)")
            } label: {
                Label("Mock exams", systemImage: "timer")
            }
            LabeledContent {
                Text("\(StudyLibrary.shared.flashcards.count)")
            } label: {
                Label("Flashcards", systemImage: "rectangle.on.rectangle.angled")
            }
            LabeledContent {
                Text("\(StudyLibrary.shared.reference.count)")
            } label: {
                Label("Reference entries", systemImage: "text.book.closed.fill")
            }
            LabeledContent {
                Text("\(StudyLibrary.shared.prompts.count)")
            } label: {
                Label("Essay prompts", systemImage: "square.and.pencil")
            }
            LabeledContent {
                Text("\(Achievements.earnedCount) of \(Achievements.totalCount)")
            } label: {
                Label("Badges earned", systemImage: "rosette")
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            Link(destination: privacyURL) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: termsURL) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }
            Link(destination: supportURL) {
                Label("Support", systemImage: "questionmark.circle.fill")
            }
            LabeledContent {
                Text(appVersion)
            } label: {
                Label("Version", systemImage: "info.circle")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetProgressAlert = true
            } label: {
                Label("Reset Study Progress", systemImage: "arrow.counterclockwise")
            }
            Button(role: .destructive) {
                showResetAllAlert = true
            } label: {
                Label("Reset Everything", systemImage: "trash")
            }
        }
    }
}

#Preview {
    SettingsView()
}
