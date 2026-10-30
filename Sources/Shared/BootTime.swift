import Darwin
import Foundation

enum BootTime {
    /// Wall-clock boot time from `kern.boottime` — the same source System
    /// Information uses for "Time since boot", so time spent asleep counts.
    static func date() -> Date {
        var tv = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname("kern.boottime", &tv, &size, nil, 0) == 0 else {
            // Monotonic fallback; this one stops while the Mac sleeps.
            return Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
        }
        return Date(timeIntervalSince1970: TimeInterval(tv.tv_sec) + TimeInterval(tv.tv_usec) / 1_000_000)
    }
}
