//
//  ProgressDashboardView.swift
//  ACT prep
//

import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @State private var progress = ProgressStore.shared

    private var sortedResults: [ExamResult] {
        progress.examResults.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedResults.isEmpty && progress.totalPracticeAttempted == 0 {
                    ContentUnavailableView(
                        "No Progress Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete practice questions or a mock exam to see your progress here.")
                    )
                } else {
                    List {
                        Section("Predicted Score") {
                            predictedCard
                        }
                        if sortedResults.count >= 2 {
                            Section("Composite Score Trend") {
                                scoreChart
                            }
                        }
                        Section {
                            ForEach(UserSettings.shared.activeSubjects) { subject in
                                heatmapBlock(subject)
                            }
                        } header: {
                            Text("Topic Heatmap")
                        } footer: {
                            Text("Accuracy per topic. Grey means you haven't attempted it yet.")
                        }
                        Section("Badges") {
                            badgeGrid
                        }
                        Section("Exam History") {
                            if sortedResults.isEmpty {
                                Text("No mock exams taken yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(sortedResults.reversed()) { result in
                                    resultRow(result)
                                }
                            }
                        }
                        Section("Practice Accuracy") {
                            ForEach(Subject.allCases) { subject in
                                practiceRow(subject)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    // MARK: Predicted score

    private var predictedCard: some View {
        let settings = UserSettings.shared
        let predicted = progress.predictedComposite(includeScience: settings.includesScience)
        let target = settings.targetScore
        let gap = predicted.map { target - $0 }

        return HStack(spacing: 18) {
            VStack(spacing: 2) {
                Text(predicted.map(String.init) ?? "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
                Text("predicted")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 5) {
                if let predicted {
                    Text("Target \(target)")
                        .font(.subheadline.weight(.medium))
                    if let gap, gap > 0 {
                        Text("\(gap) point\(gap == 1 ? "" : "s") to go")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Label("You're at or above your target", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Text("Blends your recent mock exams with practice accuracy. Estimate only.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Answer a few more questions or take a mock exam to see a prediction.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: Heatmap

    private func heatmapBlock(_ subject: Subject) -> some View {
        let stats = progress.topicStats(for: subject)
        return VStack(alignment: .leading, spacing: 8) {
            Label(subject.displayName, systemImage: subject.symbolName)
                .font(.subheadline.bold())
            ForEach(stats) { stat in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(heatColor(stat))
                        .frame(width: 14, height: 14)
                        .accessibilityHidden(true)
                    Text(stat.topic)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text(stat.attempted == 0
                         ? "—"
                         : "\(stat.correct)/\(stat.attempted)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(stat.attempted == 0
                         ? "  "
                         : "\(Int((stat.accuracy * 100).rounded()))%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    stat.attempted == 0
                        ? "\(stat.topic): not attempted"
                        : "\(stat.topic): \(Int((stat.accuracy * 100).rounded())) percent, \(stat.correct) of \(stat.attempted)"
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func heatColor(_ stat: ProgressStore.TopicStat) -> Color {
        guard stat.attempted > 0 else { return Color.appFill }
        switch stat.accuracy {
        case ..<0.4: return .red
        case ..<0.6: return .orange
        case ..<0.8: return .yellow
        default: return .green
        }
    }

    // MARK: Badges

    private var badgeGrid: some View {
        let badges = Achievements.all()
        return LazyVGrid(columns: AdaptiveGrid.columns(minWidth: 96, spacing: 10), spacing: 14) {
            ForEach(badges) { badge in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(badge.isEarned ? badge.tint.opacity(0.18) : Color.appFill)
                            .frame(width: 46, height: 46)
                        Image(systemName: badge.isEarned ? badge.symbolName : "lock.fill")
                            .font(.title3)
                            .foregroundStyle(badge.isEarned ? badge.tint : .secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text(badge.title)
                        .font(.caption2.weight(.medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    if !badge.isEarned {
                        Text(badge.detail)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    badge.isEarned
                        ? "\(badge.title), earned"
                        : "\(badge.title), locked. \(badge.detail)"
                )
            }
        }
        .padding(.vertical, 6)
    }

    private var scoreChart: some View {
        Chart(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
            LineMark(
                x: .value("Exam", index + 1),
                y: .value("Composite", result.composite)
            )
            .symbol(.circle)
            PointMark(
                x: .value("Exam", index + 1),
                y: .value("Composite", result.composite)
            )
        }
        .chartYScale(domain: 1...36)
        .frame(height: 180)
        .padding(.vertical, 8)
    }

    private func resultRow(_ result: ExamResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Mock Exam \(result.examNumber) · \(result.mode.displayName)")
                    .font(.subheadline.weight(.medium))
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("\(result.composite)")
                    .font(.headline)
                    .foregroundStyle(.tint)
                Text("composite")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func practiceRow(_ subject: Subject) -> some View {
        let stats = progress.practiceStats(for: subject)
        let pct = stats.attempted > 0 ? Double(stats.correct) / Double(stats.attempted) : 0
        return HStack {
            Label(subject.displayName, systemImage: subject.symbolName)
                .font(.subheadline)
            Spacer()
            if stats.attempted > 0 {
                Text("\(stats.correct)/\(stats.attempted) · \(Int((pct * 100).rounded()))%")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            } else {
                Text("Not started")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
