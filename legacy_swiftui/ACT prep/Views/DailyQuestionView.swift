//
//  DailyQuestionView.swift
//  ACT prep
//
//  One free question a day, shown on the home screen. Available on the free
//  plan regardless of the practice limit — it's the daily habit hook.
//

import SwiftUI

struct DailyQuestionView: View {
    let question: Question

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let passage = QuestionBank.shared.passage(for: question) {
                        PassageBox(passage: passage)
                    }
                    QuestionCard(
                        question: question,
                        selectedIndex: selected,
                        showFeedback: true
                    ) { choice in
                        guard selected == nil else { return }
                        selected = choice
                        let correct = choice == question.correctIndex
                        ProgressStore.shared.recordPractice(questionId: question.id, correct: correct)
                        UserSettings.shared.dailyQuestionDate = Date()
                        UserSettings.shared.logPractice(seconds: 60)
                    }

                    if selected != nil {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .readableWidth()
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Question of the Day")
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
