//
//  ExamSession.swift
//  ACT prep
//

import Foundation
import Observation

@Observable
final class ExamSession {
    let exam: MockExam
    let mode: ExamMode

    struct Section {
        let subject: Subject
        let questions: [Question]
        let minutes: Int
    }

    let sections: [Section]

    private(set) var sectionIndex = 0
    private(set) var questionIndex = 0
    /// answers[questionId] = chosen index
    private(set) var answers: [String: Int] = [:]
    private(set) var secondsRemaining: Int
    private(set) var isFinished = false
    private var timer: Timer?
    private let startedAt = Date()

    /// Wall-clock seconds spent in this exam, used for the daily practice goal.
    var elapsedSeconds: Int { Int(Date().timeIntervalSince(startedAt)) }

    init(exam: MockExam, mode: ExamMode) {
        self.exam = exam
        self.mode = mode
        self.sections = Subject.allCases.map { subject in
            Section(
                subject: subject,
                questions: QuestionBank.shared.examQuestions(
                    subject: subject,
                    examIndex: exam.index,
                    count: mode.count(for: subject)
                ),
                minutes: mode.minutes(for: subject)
            )
        }
        self.secondsRemaining = (sections.first?.minutes ?? 0) * 60
        startTimer()
    }

    var currentSection: Section { sections[sectionIndex] }
    var currentQuestion: Question? {
        let qs = currentSection.questions
        return qs.indices.contains(questionIndex) ? qs[questionIndex] : nil
    }
    var isLastSection: Bool { sectionIndex == sections.count - 1 }
    var isLastQuestionInSection: Bool { questionIndex >= currentSection.questions.count - 1 }

    var answeredInCurrentSection: Int {
        currentSection.questions.filter { answers[$0.id] != nil }.count
    }

    func select(choice: Int) {
        guard let q = currentQuestion else { return }
        answers[q.id] = choice
    }

    func selectedChoice() -> Int? {
        currentQuestion.flatMap { answers[$0.id] }
    }

    func goToNext() {
        if !isLastQuestionInSection {
            questionIndex += 1
        }
    }

    func goToPrevious() {
        if questionIndex > 0 {
            questionIndex -= 1
        }
    }

    func jump(to index: Int) {
        guard currentSection.questions.indices.contains(index) else { return }
        questionIndex = index
    }

    /// Ends the current section; advances to the next or finishes the exam.
    func endSection() {
        if isLastSection {
            finish()
        } else {
            sectionIndex += 1
            questionIndex = 0
            secondsRemaining = currentSection.minutes * 60
        }
    }

    func finish() {
        guard !isFinished else { return }
        isFinished = true
        stopTimer()
    }

    func result() -> ExamResult {
        let sectionResults = sections.map { section in
            SectionResult(
                subject: section.subject,
                correct: section.questions.filter { answers[$0.id] == $0.correctIndex }.count,
                total: section.questions.count
            )
        }
        return ExamResult(
            id: UUID(),
            examNumber: exam.number,
            mode: mode,
            date: Date(),
            sections: sectionResults
        )
    }

    // MARK: Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.endSection()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    var timeString: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    deinit { timer?.invalidate() }
}
