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
    private var dirty = false
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {
        secondsByDay = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Double] ?? [:]
        // Make "today" roll over at midnight or across timezone changes even while idle
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil,
                                               queue: .main) { [weak self] _ in
            self?.objectWillChange.send()
        }
        NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil,
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
        if dirty {
            save()
        }
    }

    func save() {
        lastSave = Date()
        dirty = false
        UserDefaults.standard.set(secondsByDay, forKey: storageKey)
    }

    /// Splits the interval at midnight so each part counts towards its own day
    func add(from start: Date, to end: Date) {
        let calendar = Calendar.current
        var cursor = start
        while cursor < end {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor)),
                  nextDay > cursor else { break }
            let segmentEnd = min(end, nextDay)
            secondsByDay[dayFormatter.string(from: cursor), default: 0] += segmentEnd.timeIntervalSince(cursor)
            dirty = true
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
            guard let next = calendar.date(byAdding: .day, value: 1, to: day),
                  next > day else { break }
            day = next
        }
        return days
    }

    func total(inMonthOf date: Date) -> Double {
        days(inMonthOf: date).reduce(0) { $0 + seconds(on: $1) }
    }
}

private struct DurationFormatterKey: Hashable {
    let localeId: String
    let compact: Bool
    let showsHours: Bool
}

private var durationFormatterCache: [DurationFormatterKey: DateComponentsFormatter] = [:]

/// Whole minutes displayed for a recorded duration (rounds up within 0.5s of a full minute)
func displayedMinutes(for seconds: Double) -> Int {
    guard seconds > 0 else { return 0 }
    return Int((seconds + 0.5) / 60)
}

/// "1 h 23 min" style durations in the app's language; `compact` gives "1h 23m" for tight spaces
func formatDuration(_ seconds: Double, compact: Bool = false) -> String {
    let minutes = displayedMinutes(for: seconds)
    let showsHours = minutes >= 60
    let locale = L10n.shared.locale
    let key = DurationFormatterKey(localeId: locale.identifier, compact: compact, showsHours: showsHours)
    let formatter: DateComponentsFormatter
    if let cached = durationFormatterCache[key] {
        formatter = cached
    } else {
        let f = DateComponentsFormatter()
        var calendar = Calendar.current
        calendar.locale = locale
        f.calendar = calendar
        f.unitsStyle = compact ? .abbreviated : .short
        f.allowedUnits = showsHours ? [.hour, .minute] : [.minute]
        f.zeroFormattingBehavior = showsHours ? .dropTrailing : .pad
        durationFormatterCache[key] = f
        formatter = f
    }
    return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)"
}
