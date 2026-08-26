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
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalCard
                    scoreCard
                    if !store.isPro { proBanner }
                    quickActions
                    subjectSnapshot
                }
                .padding()
                .readableWidth(760)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(greeting)
            .sheet(isPresented: $showPaywall) { PaywallView() }
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
