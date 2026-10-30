import Foundation

/// Everything the widget draws, as of `date`.
struct UptimeSnapshot {
    let date: Date
    let bootDate: Date
    /// Time spent awake since boot; `elapsed` minus this is time asleep.
    let awake: TimeInterval

    var elapsed: TimeInterval { max(0, date.timeIntervalSince(bootDate)) }
    var days: Int { Int(elapsed / 86_400) }
    /// Start of the current 24-hour lap; the dial and the clock count from here.
    var lapStart: Date { bootDate.addingTimeInterval(Double(days) * 86_400) }
    var lapElapsed: TimeInterval { elapsed - Double(days) * 86_400 }
    var lapProgress: Double { lapElapsed / 86_400 }
    var awakeFraction: Double { elapsed > 0 ? min(1, awake / elapsed) : 1 }

    struct Day {
        let start: Date
        let upFraction: Double
        let isToday: Bool
    }

    /// The last seven calendar days and how much of each the Mac was up.
    var lastSevenDays: [Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().map { back in
            let start = calendar.date(byAdding: .day, value: -back, to: today)!
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let up = max(0, min(end, date).timeIntervalSince(max(start, bootDate)))
            return Day(start: start, upFraction: up / end.timeIntervalSince(start), isToday: back == 0)
        }
    }

    /// Snapshots starting now, `step` apart, plus one at each moment the day count
    /// or the clock's padding changes. Assumes the Mac stays awake, which holds
    /// whenever the widget is actually on screen.
    static func timeline(count: Int, every step: TimeInterval) -> [UptimeSnapshot] {
        let now = Date.now
        let boot = BootTime.date()
        let awakeNow = ProcessInfo.processInfo.systemUptime   // stops while asleep
        let end = now.addingTimeInterval(Double(count) * step)

        var dates = (0..<count).map { now.addingTimeInterval(Double($0) * step) }
        var lap = UptimeSnapshot(date: now, bootDate: boot, awake: 0).lapStart
        while lap < end {
            for mark in [0, 600, 3600].map({ lap.addingTimeInterval($0) }) where mark > now && mark < end {
                dates.append(mark)
            }
            lap.addTimeInterval(86_400)
        }

        return dates.sorted().map {
            UptimeSnapshot(date: $0, bootDate: boot, awake: awakeNow + $0.timeIntervalSince(now))
        }
    }

    static var current: UptimeSnapshot { timeline(count: 1, every: 0)[0] }

    /// Placeholder data: 1 day 14 h 6 min up, 82% of it awake.
    static var sample: UptimeSnapshot {
        let elapsed: TimeInterval = 38 * 3600 + 6 * 60
        return UptimeSnapshot(date: .now, bootDate: .now.addingTimeInterval(-elapsed), awake: elapsed * 0.82)
    }
}
