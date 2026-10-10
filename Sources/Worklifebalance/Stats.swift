import SwiftUI

/// Focus time per calendar day, keyed by the computer's local date
class TBStats: ObservableObject {
    static let shared = TBStats()

    private let storageKey = "focusSecondsByDay"
    /// Longer gaps between ticks (sleep, clock changes) are not counted as focus time
    private let maxTickGap: TimeInterval = 5
    private let saveInterval: TimeInterval = 15

    @Published private(set) var secondsByDay: [String: Double]
    private var lastMark: Date?
    private var lastSave = Date()
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {
        secondsByDay = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Double] ?? [:]
        // Make "today" roll over at midnight even while nothing is running
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil,
                                               queue: .main) { [weak self] _ in
            self?.objectWillChange.send()
        }
        NotificationCenter.default.addObserver(forName: .NSSystemClockDidChange, object: nil,
                                               queue: .main) { [weak self] _ in
            // Don't count a jump of the clock as focus time
            if self?.lastMark != nil { self?.lastMark = Date() }
            self?.objectWillChange.send()
        }
    }

    /// Call when focus starts or resumes
    func begin() {
        lastMark = Date()
    }

    /// Call on every tick while focusing
    func mark() {
        guard let last = lastMark else { return }
        let now = Date()
        lastMark = now
        let gap = now.timeIntervalSince(last)
        guard gap > 0, gap <= maxTickGap else { return }
        add(from: last, to: now)
        if now.timeIntervalSince(lastSave) >= saveInterval {
            save()
        }
    }

    /// Call when focus pauses, stops or finishes
    func end() {
        mark()
        lastMark = nil
        save()
    }

    func save() {
        lastSave = Date()
        UserDefaults.standard.set(secondsByDay, forKey: storageKey)
    }

    /// Splits the interval at midnight so each part counts towards its own day
    func add(from start: Date, to end: Date) {
        let calendar = Calendar.current
        var cursor = start
        while cursor < end {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor))!
            let segmentEnd = min(end, nextDay)
            secondsByDay[dayFormatter.string(from: cursor), default: 0] += segmentEnd.timeIntervalSince(cursor)
            cursor = segmentEnd
        }
    }

    func seconds(on date: Date) -> Double {
        secondsByDay[dayFormatter.string(from: date)] ?? 0
    }

    var today: Double {
        seconds(on: Date())
    }

    /// Days of the month containing `date`, up to today for the current month
    func days(inMonthOf date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let todayStart = calendar.startOfDay(for: Date())
        var days: [Date] = []
        var day = interval.start
        while day < interval.end, day <= todayStart {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return days
    }

    func total(inMonthOf date: Date) -> Double {
        days(inMonthOf: date).reduce(0) { $0 + seconds(on: $1) }
    }
}

/// "1 h 23 min" style durations in the app's language; `compact` gives "1h 23m" for tight spaces
func formatDuration(_ seconds: Double, compact: Bool = false) -> String {
    let formatter = DateComponentsFormatter()
    var calendar = Calendar.current
    calendar.locale = L10n.shared.locale
    formatter.calendar = calendar
    formatter.unitsStyle = compact ? .abbreviated : .short
    let minutes = Int(seconds / 60)
    formatter.allowedUnits = minutes >= 60 ? [.hour, .minute] : [.minute]
    formatter.zeroFormattingBehavior = minutes >= 60 ? .dropTrailing : .pad
    return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
}
