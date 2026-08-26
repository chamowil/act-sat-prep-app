//
//  QuestionCard.swift
//  ACT prep
//

import SwiftUI

/// Renders one question with its choices. Used by both practice and exam modes.
/// - In practice mode (`showFeedback == true`) the correct/incorrect state is
///   revealed as soon as a choice is made and the explanation is shown.
/// - In exam mode choices just highlight the selection.
struct QuestionCard: View {
    let question: Question
    let selectedIndex: Int?
    let showFeedback: Bool
    let onSelect: (Int) -> Void

    private let letters = ["A", "B", "C", "D", "E"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(question.topic, systemImage: "tag.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                Spacer()
                DifficultyDots(level: question.difficulty)
            }

            Text(question.prompt)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(question.choices.indices, id: \.self) { i in
                    choiceRow(i)
                }
            }

            if showFeedback, selectedIndex != nil {
                explanationBox
            }
        }
    }

    private func choiceRow(_ i: Int) -> some View {
        let state = choiceState(i)
        return Button {
            onSelect(i)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(letters[min(i, letters.count - 1)])
                    .font(.subheadline.bold())
                    .frame(width: 28, height: 28)
                    .background(state.badgeColor, in: Circle())
                    .foregroundStyle(state.badgeTextColor)
                Text(question.choices[i])
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let symbol = state.trailingSymbol {
                    Image(systemName: symbol)
                        .foregroundStyle(state.trailingColor)
                }
            }
            .padding(12)
            .background(state.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(state.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(showFeedback && selectedIndex != nil)
    }

    private struct ChoiceState {
        var background: Color = Color(.secondarySystemGroupedBackground)
        var border: Color = .clear
        var badgeColor: Color = Color(.tertiarySystemFill)
        var badgeTextColor: Color = .primary
        var trailingSymbol: String?
        var trailingColor: Color = .clear
    }

    private func choiceState(_ i: Int) -> ChoiceState {
        var state = ChoiceState()
        let isSelected = selectedIndex == i

        if showFeedback, let selected = selectedIndex {
            if i == question.correctIndex {
                state.background = Color.green.opacity(0.14)
                state.border = .green
                state.badgeColor = .green
                state.badgeTextColor = .white
                state.trailingSymbol = "checkmark.circle.fill"
                state.trailingColor = .green
            } else if i == selected {
                state.background = Color.red.opacity(0.12)
                state.border = .red
                state.badgeColor = .red
                state.badgeTextColor = .white
                state.trailingSymbol = "xmark.circle.fill"
                state.trailingColor = .red
            }
        } else if isSelected {
            state.border = .accentColor
            state.badgeColor = .accentColor
            state.badgeTextColor = .white
        }
        return state
    }

    private var explanationBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(
                selectedIndex == question.correctIndex ? "Correct!" : "Not quite",
                systemImage: selectedIndex == question.correctIndex
                    ? "checkmark.seal.fill" : "lightbulb.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(selectedIndex == question.correctIndex ? .green : .orange)
            Text(question.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DifficultyDots: View {
    let level: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.orange : Color(.tertiarySystemFill))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("Difficulty \(level) of 3")
    }
}

/// Collapsible passage shown above passage-based questions.
struct PassageBox: View {
    let passage: Passage
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack {
                    Label(passage.title, systemImage: "doc.plaintext.fill")
                        .font(.subheadline.bold())
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(passage.text)
                        .font(.callout)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
