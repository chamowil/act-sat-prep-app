//
//  UserSettings.swift
//  ACT prep
//

import Foundation
import Observation

/// User-chosen study goals, collected during first-launch onboarding and
/// editable afterwards in Settings. Backed by UserDefaults so it is available
/// synchronously at launch.
@Observable
final class UserSettings {
    static let shared = UserSettings()

    private enum Key {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let targetScore = "targetScore"
        static let dailyMinutes = "dailyMinutes"
        static let testDate = "testDate"
        static let name = "studentName"
        static let practiceLog = "practiceLog"
        static let includesScience = "includesScience"
        static let hasTakenDiagnostic = "hasTakenDiagnostic"
        static let dailyQuestionDate = "dailyQuestionDate"
    }

    /// Allowed daily-practice choices, in minutes.
    static let dailyMinuteOptions = [10, 15, 20, 30, 45, 60]

    private let defaults = UserDefaults.standard

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    /// Goal composite score, 1...36.
    var targetScore: Int {
        didSet { defaults.set(targetScore, forKey: Key.targetScore) }
    }

    /// Daily practice goal in minutes.
    var dailyMinutes: Int {
        didSet { defaults.set(dailyMinutes, forKey: Key.dailyMinutes) }
    }

    /// Optional planned ACT test date.
    var testDate: Date? {
        didSet {
            if let testDate {
                defaults.set(testDate, forKey: Key.testDate)
            } else {
                defaults.removeObject(forKey: Key.testDate)
            }
        }
    }

    var name: String {
        didSet { defaults.set(name, forKey: Key.name) }
    }

    /// Whether the student is taking the ACT with the Science section.
    /// Turning this off removes Science from mock exams and score predictions.
    var includesScience: Bool {
        didSet { defaults.set(includesScience, forKey: Key.includesScience) }
    }

    var hasTakenDiagnostic: Bool {
        didSet { defaults.set(hasTakenDiagnostic, forKey: Key.hasTakenDiagnostic) }
    }

    /// The day the daily question was last answered, for the Home streak card.
    var dailyQuestionDate: Date? {
        didSet {
            if let dailyQuestionDate {
                defaults.set(dailyQuestionDate, forKey: Key.dailyQuestionDate)
            } else {
                defaults.removeObject(forKey: Key.dailyQuestionDate)
            }
        }
    }

    /// Subjects that count toward this student's exam, honoring the Science toggle.
    var activeSubjects: [Subject] {
        includesScience ? Subject.allCases : Subject.allCases.filter { $0 != .science }
    }

    /// Minutes practiced, keyed by day (start of day).
    private(set) var practiceLog: [Date: Int]

    private init() {
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        let storedTarget = defaults.integer(forKey: Key.targetScore)
        targetScore = storedTarget == 0 ? 30 : storedTarget
        let storedMinutes = defaults.integer(forKey: Key.dailyMinutes)
        dailyMinutes = storedMinutes == 0 ? 20 : storedMinutes
        testDate = defaults.object(forKey: Key.testDate) as? Date
        name = defaults.string(forKey: Key.name) ?? ""
        includesScience = defaults.object(forKey: Key.includesScience) as? Bool ?? true
        hasTakenDiagnostic = defaults.bool(forKey: Key.hasTakenDiagnostic)
        dailyQuestionDate = defaults.object(forKey: Key.dailyQuestionDate) as? Date

        if let raw = defaults.dictionary(forKey: Key.practiceLog) as? [String: Int] {
            var log: [Date: Int] = [:]
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            for (key, value) in raw {
                if let date = formatter.date(from: key) { log[date] = value }
            }
            practiceLog = log
        } else {
            practiceLog = [:]
        }
    }

    // MARK: Daily goal tracking

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    var minutesPracticedToday: Int { practiceLog[today] ?? 0 }

    var dailyGoalProgress: Double {
        guard dailyMinutes > 0 else { return 0 }
        return min(1, Double(minutesPracticedToday) / Double(dailyMinutes))
    }

    var hasMetDailyGoal: Bool { minutesPracticedToday >= dailyMinutes }

    func logPractice(seconds: Int) {
        guard seconds > 0 else { return }
        let minutes = max(1, Int((Double(seconds) / 60).rounded()))
        practiceLog[today, default: 0] += minutes
        persistLog()
    }

    private func persistLog() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        var raw: [String: Int] = [:]
        // Keep the log bounded: the last 120 days is plenty for streaks.
        let cutoff = Calendar.current.date(byAdding: .day, value: -120, to: today) ?? today
        for (date, minutes) in practiceLog where date >= cutoff {
            raw[formatter.string(from: date)] = minutes
        }
        defaults.set(raw, forKey: Key.practiceLog)
    }

    /// Consecutive days (ending today or yesterday) that met the daily goal.
    var streak: Int {
        var count = 0
        var day = today
        let calendar = Calendar.current
        // Allow the streak to survive until today's session happens.
        if (practiceLog[day] ?? 0) < dailyMinutes {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        while (practiceLog[day] ?? 0) >= dailyMinutes {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var daysUntilTest: Int? {
        guard let testDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: testDate)).day
        guard let days, days >= 0 else { return nil }
        return days
    }

    var answeredDailyQuestionToday: Bool {
        guard let dailyQuestionDate else { return false }
        return Calendar.current.isDateInToday(dailyQuestionDate)
    }

    /// A stable "question of the day": the same question all day, a new one
    /// tomorrow, derived from the date so it needs no stored schedule.
    func dailyQuestion() -> Question? {
        let pool = activeSubjects.flatMap { QuestionBank.shared.questions(for: $0) }
        guard !pool.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return pool[day % pool.count]
    }

    /// A suggested weekly workload derived from the test date and daily goal.
    var weeklyPlan: (sessionsPerWeek: Int, minutesPerWeek: Int, weeksLeft: Int?) {
        let weeks = daysUntilTest.map { max(1, Int(ceil(Double($0) / 7.0))) }
        return (7, dailyMinutes * 7, weeks)
    }

    func reset() {
        hasCompletedOnboarding = false
        targetScore = 30
        dailyMinutes = 20
        testDate = nil
        name = ""
        includesScience = true
        hasTakenDiagnostic = false
        dailyQuestionDate = nil
        practiceLog = [:]
        defaults.removeObject(forKey: Key.practiceLog)
    }
}
