//
//  HomeView.swift
//  ACT prep
//

import SwiftUI

struct HomeView: View {
    @State private var store = StoreManager.shared
    @State private var progress = ProgressStore.shared
    @State private var settings = UserSettings.shared
    @State private var showPaywall = false
    @State private var showDailyQuestion = false
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalCard
                    scoreCard
                    if !settings.hasTakenDiagnostic { diagnosticPrompt }
                    dailyQuestionCard
                    if !store.isPro { proBanner }
                    quickActions
                    weakSpots
                    subjectSnapshot
                    badgeStrip
                }
                .padding()
                .readableWidth(760)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(greeting)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showDailyQuestion) {
                if let question = settings.dailyQuestion() {
                    DailyQuestionView(question: question)
                }
            }
        }
    }

    private var greeting: String {
        settings.name.isEmpty ? "ACT Prep" : "Hi, \(settings.name)"
    }

    // MARK: Daily goal

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's Goal")
                        .font(.headline)
                    Text("\(settings.minutesPracticedToday) of \(settings.dailyMinutes) minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if settings.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(settings.streak)")
                            .font(.headline.monospacedDigit())
                    }
                    .accessibilityLabel("\(settings.streak) day streak")
                }
            }

            ProgressView(value: settings.dailyGoalProgress)
                .tint(settings.hasMetDailyGoal ? .green : .accentColor)

            HStack(spacing: 14) {
                Label("Target \(settings.targetScore)", systemImage: "target")
                if let days = settings.daysUntilTest {
                    Label(
                        days == 0 ? "Test is today" : "\(days) day\(days == 1 ? "" : "s") to test",
                        systemImage: "calendar"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .cardBackground()
    }

    // MARK: Scores

    private var scoreCard: some View {
        HStack(spacing: 0) {
            scoreStat(title: "Latest", value: progress.latestComposite.map(String.init) ?? "—")
            Divider().frame(height: 44)
            scoreStat(title: "Best", value: progress.bestComposite.map(String.init) ?? "—")
            Divider().frame(height: 44)
            scoreStat(title: "Practiced", value: "\(progress.totalPracticeAttempted)")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }

    private func scoreStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.tint)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Diagnostic nudge

    private var diagnosticPrompt: some View {
        Button {
            selectedTab = .practice
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "stethoscope")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Take the diagnostic first")
                        .font(.headline)
                    Text("35 minutes to find your baseline and weak spots")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .cardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Question of the day

    @ViewBuilder
    private var dailyQuestionCard: some View {
        if let question = settings.dailyQuestion() {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Question of the Day", systemImage: "sun.max.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    Spacer()
                    if settings.answeredDailyQuestionToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityLabel("Answered today")
                    }
                }

                if settings.answeredDailyQuestionToday {
                    Text("Done for today — a new one arrives tomorrow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(question.prompt)
                        .font(.subheadline)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        showDailyQuestion = true
                    } label: {
                        Label("Answer now", systemImage: "arrow.right.circle.fill")
                            .font(.subheadline.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardBackground()
        }
    }

    // MARK: Weak spots

    @ViewBuilder
    private var weakSpots: some View {
        let weak = progress.weakestTopics(limit: 3)
        if !weak.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus Next")
                    .font(.headline)
                Text("Your lowest-accuracy topics so far.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(weak) { stat in
                    HStack(spacing: 10) {
                        Image(systemName: stat.subject.symbolName)
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(stat.topic)
                                .font(.subheadline.weight(.medium))
                            Text(stat.subject.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int((stat.accuracy * 100).rounded()))%")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(stat.accuracy < 0.5 ? .red : .orange)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardBackground()
        }
    }

    // MARK: Badges

    private var badgeStrip: some View {
        let badges = Achievements.all()
        let earned = badges.filter(\.isEarned)
        let next = badges.filter { !$0.isEarned }.sorted { $0.progress > $1.progress }.prefix(2)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges").font(.headline)
                Spacer()
                Text("\(earned.count) of \(badges.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if earned.isEmpty && next.isEmpty {
                Text("Start practicing to earn your first badge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(earned) { badgeChip($0) }
                        ForEach(Array(next)) { badgeChip($0) }
                    }
                }
            }
        }
        .padding()
        .cardBackground()
    }

    private func badgeChip(_ badge: Badge) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? badge.tint.opacity(0.18) : Color.appFill)
                    .frame(width: 48, height: 48)
                Image(systemName: badge.isEarned ? badge.symbolName : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(badge.isEarned ? badge.tint : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            Text(badge.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(badge.isEarned ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 76)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            badge.isEarned
                ? "\(badge.title), earned. \(badge.detail)"
                : "\(badge.title), locked. \(badge.detail). \(Int(badge.progress * 100)) percent there."
        )
    }

    // MARK: Pro banner

    private var proBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Pro")
                        .font(.headline)
                    Text("All 520 questions, 40 tutorials, and 15 mock exams")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .cardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Quick actions

    private var quickActions: some View {
        LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 150), spacing: 12) {
            actionCard(
                title: "Tutorials",
                subtitle: "Math & Science review",
                symbol: "book.fill",
                tab: .learn
            )
            actionCard(
                title: "Practice",
                subtitle: "By subject & topic",
                symbol: "pencil.and.list.clipboard",
                tab: .practice
            )
            actionCard(
                title: "Mock Exam",
                subtitle: "Quick or full-length",
                symbol: "timer",
                tab: .practice
            )
            actionCard(
                title: "Progress",
                subtitle: "Scores & analytics",
                symbol: "chart.line.uptrend.xyaxis",
                tab: .progress
            )
        }
    }

    private func actionCard(title: String, subtitle: String, symbol: String, tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .cardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Accuracy

    private var subjectSnapshot: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subject Accuracy")
                .font(.headline)
            ForEach(Subject.allCases) { subject in
                let stats = progress.practiceStats(for: subject)
                let pct = stats.attempted > 0 ? Double(stats.correct) / Double(stats.attempted) : 0
                HStack(spacing: 12) {
                    Image(systemName: subject.symbolName)
                        .foregroundStyle(.tint)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    Text(subject.displayName)
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    ProgressView(value: pct)
                        .tint(pct >= 0.7 ? .green : (pct >= 0.4 ? .orange : .red))
                    Text(stats.attempted > 0 ? "\(Int((pct * 100).rounded()))%" : "—")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    stats.attempted > 0
                        ? "\(subject.displayName): \(Int((pct * 100).rounded())) percent"
                        : "\(subject.displayName): not started"
                )
            }
        }
        .padding()
        .cardBackground()
    }
}
