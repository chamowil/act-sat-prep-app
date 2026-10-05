//
//  OnboardingView.swift
//  ACT prep
//

import SwiftUI

/// First-launch setup: welcome, target score, daily practice goal, optional
/// test date. Presented over the app until the student finishes it.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = UserSettings.shared
    @State private var step = 0

    @State private var name = ""
    @State private var targetScore = 30.0
    @State private var dailyMinutes = 20
    @State private var wantsTestDate = false
    @State private var testDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    private let stepCount = 4

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            // A plain switch (rather than a paged TabView) keeps every control
            // tappable: a paging TabView's drag gesture swallows taps on
            // toggles and sliders inside its pages.
            Group {
                switch step {
                case 0: welcomeStep
                case 1: targetScoreStep
                case 2: dailyGoalStep
                default: testDateStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.snappy, value: step)

            controls
        }
        .background(Color.appGroupedBackground)
        .interactiveDismissDisabled()
    }

    // MARK: Chrome

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.accentColor : Color.appFill)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of \(stepCount)")
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                advance()
            } label: {
                Text(step == stepCount - 1 ? "Start Studying" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)

            if step > 0 {
                Button("Back") {
                    withAnimation(.snappy) { step -= 1 }
                }
                .font(.subheadline)
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
    }

    private func advance() {
        if step < stepCount - 1 {
            withAnimation(.snappy) { step += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        settings.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.targetScore = Int(targetScore.rounded())
        settings.dailyMinutes = dailyMinutes
        settings.testDate = wantsTestDate ? testDate : nil
        settings.hasCompletedOnboarding = true
        dismiss()
    }

    // MARK: Steps

    private func stepScaffold<Content: View>(
        symbol: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .padding(.top, 32)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                content()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private var welcomeStep: some View {
        stepScaffold(
            symbol: "graduationcap.fill",
            title: "Welcome to ACT Prep",
            subtitle: "Over 500 practice questions, 40 tutorials, and 15 full mock exams. Let's set up your study plan."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("What should we call you?")
                    .font(.subheadline.weight(.medium))
                TextField("Your first name (optional)", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .onSubmit(advance)
            }
        }
    }

    private var targetScoreStep: some View {
        stepScaffold(
            symbol: "target",
            title: "What's your goal?",
            subtitle: "Pick the composite ACT score you're aiming for. You can change this any time."
        ) {
            VStack(spacing: 16) {
                Text("\(Int(targetScore.rounded()))")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(targetScore.rounded()))
                Text("out of 36")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $targetScore, in: 1...36, step: 1) {
                    Text("Target score")
                } minimumValueLabel: {
                    Text("1").font(.caption2)
                } maximumValueLabel: {
                    Text("36").font(.caption2)
                }
                .accessibilityValue("\(Int(targetScore.rounded())) out of 36")

                Text(goalDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var goalDescription: String {
        switch Int(targetScore.rounded()) {
        case 1...17: return "A solid starting goal. Focus on the fundamentals in the Tutorials tab first."
        case 18...23: return "Around the national average. Steady daily practice moves this quickly."
        case 24...29: return "A competitive score at many universities. Timing drills matter here."
        case 30...33: return "A strong score for selective schools. Accuracy on hard questions is key."
        default: return "A top-percentile goal. You'll need near-perfect accuracy and pacing."
        }
    }

    private var dailyGoalStep: some View {
        stepScaffold(
            symbol: "clock.badge.checkmark.fill",
            title: "How much time per day?",
            subtitle: "Short daily sessions beat occasional long ones. We'll track your streak."
        ) {
            VStack(spacing: 10) {
                ForEach(UserSettings.dailyMinuteOptions, id: \.self) { minutes in
                    Button {
                        dailyMinutes = minutes
                    } label: {
                        HStack {
                            Text("\(minutes) minutes")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(minuteHint(minutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: dailyMinutes == minutes ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(dailyMinutes == minutes ? Color.accentColor : .secondary)
                        }
                        .padding()
                        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(dailyMinutes == minutes ? Color.accentColor : .clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(dailyMinutes == minutes ? .isSelected : [])
                }
            }
        }
    }

    private func minuteHint(_ minutes: Int) -> String {
        switch minutes {
        case 10: return "~6 questions"
        case 15: return "~10 questions"
        case 20: return "~13 questions"
        case 30: return "~20 questions"
        case 45: return "~30 questions"
        default: return "~40 questions"
        }
    }

    private var testDateStep: some View {
        stepScaffold(
            symbol: "calendar",
            title: "When do you test?",
            subtitle: "Add your ACT date and we'll show a countdown on the home screen."
        ) {
            VStack(spacing: 16) {
                Button {
                    withAnimation(.snappy) { wantsTestDate.toggle() }
                } label: {
                    HStack {
                        Text("I have a test date")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: wantsTestDate ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(wantsTestDate ? Color.accentColor : .secondary)
                    }
                    .padding()
                    .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(wantsTestDate ? .isSelected : [])

                if wantsTestDate {
                    DatePicker(
                        "Test date",
                        selection: $testDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(8)
                    .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                }

                summaryCard
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your plan", systemImage: "sparkles")
                .font(.subheadline.bold())
            Text("Target score \(Int(targetScore.rounded())) · \(dailyMinutes) minutes a day")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if wantsTestDate {
                Text("Test on \(testDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView()
}
