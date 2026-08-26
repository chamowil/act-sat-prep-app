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
                        if sortedResults.count >= 2 {
                            Section("Composite Score Trend") {
                                scoreChart
                            }
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
