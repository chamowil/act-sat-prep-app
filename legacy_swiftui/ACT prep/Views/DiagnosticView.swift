//
//  DiagnosticView.swift
//  ACT prep
//
//  Baseline placement test: a short timed run across every active section that
//  produces a starting score and a ranked list of weak areas.
//

import SwiftUI

struct DiagnosticIntroView: View {
    @State private var settings = UserSettings.shared
    @State private var progress = ProgressStore.shared
    @State private var isRunning = false

    private var questionCount: Int {
        settings.activeSubjects.reduce(0) { $0 + $1.diagnosticCount }
    }
    private var minutes: Int {
        settings.activeSubjects.reduce(0) { $0 + $1.diagnosticMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    point("gauge.with.needle", "Find your starting score",
                          "A scaled score for each section and an overall composite.")
                    point("chart.bar.xaxis", "See your weakest topics",
                          "Ranked by accuracy, so you know exactly what to study first.")
                    point("clock", "\(questionCount) questions · about \(minutes) minutes",
                          "Timed by section, like the real test.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                if settings.hasTakenDiagnostic {
                    Label("You've already taken the diagnostic. Retaking it replaces nothing — it just adds another result to your history.",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                        .cardBackground(cornerRadius: 12)
                }

                Button {
                    isRunning = true
                } label: {
                    Label(settings.hasTakenDiagnostic ? "Retake Diagnostic" : "Start Diagnostic",
                          systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Text("Answer honestly and don't guess wildly — an accurate baseline makes every recommendation that follows more useful.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .readableWidth(620)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Diagnostic Test")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fullScreenCover(isPresented: $isRunning) {
            ExamRunnerView(exam: MockExam.diagnostic, mode: .diagnostic)
        }
        .onChange(of: isRunning) { old, new in
            if old && !new { settings.hasTakenDiagnostic = true }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "stethoscope")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Where are you starting from?")
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text("Take this once, before you study. Everything the app recommends works better when it knows your baseline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private func point(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
