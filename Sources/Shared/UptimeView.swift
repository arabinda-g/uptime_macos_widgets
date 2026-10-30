import SwiftUI
import WidgetKit

enum UptimeLayout { case small, medium }

enum Palette {
    static let mint = Color(hex: 0x2EE6A8)
    static let cyan = Color(hex: 0x1FB6FF)
    static let indigo = Color(hex: 0x6E6BFF)
    static let live = Color(hex: 0x30D158)
    /// Runs clockwise from midnight on the dial: mint at hour 0, indigo at hour 24.
    static let dial = AngularGradient(colors: [mint, cyan, indigo], center: .center,
                                      startAngle: .degrees(0), endAngle: .degrees(360))
    static let bar = LinearGradient(colors: [cyan, mint], startPoint: .bottom, endPoint: .top)

    static func accentText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? mint : Color(hex: 0x0A9A72)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct UptimeBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(colors: scheme == .dark ? [Color(hex: 0x1C2338), Color(hex: 0x07090F)]
                                               : [Color(hex: 0xFFFFFF), Color(hex: 0xE4EBF6)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// `tinted` is true when macOS draws the widget monochrome (accented or vibrant),
/// where the background is removed and colour turns into opacity.
struct UptimeView: View {
    let snapshot: UptimeSnapshot
    var layout: UptimeLayout = .medium
    var tinted = false

    var body: some View {
        Group {
            switch layout {
            case .small:
                VStack(spacing: 6) {
                    Header(tinted: tinted)
                    dial(lineWidth: 8, clockSize: 18)
                }
            case .medium:
                HStack(spacing: 18) {
                    dial(lineWidth: 9, clockSize: 20)
                    VStack(alignment: .leading, spacing: 0) {
                        Header(tinted: tinted)
                        Spacer(minLength: 8)
                        HStack(alignment: .top, spacing: 16) {
                            Stat(label: "BOOTED", value: Text(snapshot.bootDate, format: bootFormat))
                            Stat(label: "AWAKE", value: Text(snapshot.awakeFraction, format: .percent.precision(.fractionLength(0))))
                        }
                        Spacer(minLength: 8)
                        WeekBars(days: snapshot.lastSevenDays, tinted: tinted)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Uptime \(Duration.seconds(snapshot.elapsed).formatted(.units(allowed: [.days, .hours, .minutes], width: .wide)))")
    }

    private func dial(lineWidth: CGFloat, clockSize: CGFloat) -> some View {
        ZStack {
            if !tinted { Glow() }
            HourDial(progress: snapshot.lapProgress, lineWidth: lineWidth, tinted: tinted)
            DialCenter(snapshot: snapshot, clockSize: clockSize, tinted: tinted)
                .padding(.horizontal, lineWidth + 6)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Weekday and time while the boot is recent, otherwise the date.
    private var bootFormat: Date.FormatStyle {
        snapshot.elapsed < 6 * 86_400
            ? .dateTime.weekday(.abbreviated).hour().minute()
            : .dateTime.month(.abbreviated).day()
    }
}

/// 24 segments, one per hour of the current day of uptime. Also drawn on the app icon.
struct HourDial: View {
    let progress: Double
    let lineWidth: CGFloat
    let tinted: Bool

    private let gap = 0.0045

    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<24, id: \.self) { hour in
                    Circle()
                        .trim(from: Double(hour) / 24 + gap, to: Double(hour + 1) / 24 - gap)
                        .stroke(.primary.opacity(0.12), style: StrokeStyle(lineWidth: lineWidth))
                }
            }
            ZStack {
                ForEach(0..<24, id: \.self) { hour in
                    let start = Double(hour) / 24 + gap
                    if progress > start {
                        Circle()
                            .trim(from: start, to: min(Double(hour + 1) / 24 - gap, progress))
                            .stroke(tinted ? AnyShapeStyle(.primary) : AnyShapeStyle(Palette.dial),
                                    style: StrokeStyle(lineWidth: lineWidth))
                    }
                }
            }
            .shadow(color: Palette.cyan.opacity(tinted ? 0 : 0.55), radius: 5)
            .widgetAccentable()
        }
        .rotationEffect(.degrees(-90))
        .padding(lineWidth / 2)
    }
}

private struct DialCenter: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: UptimeSnapshot
    let clockSize: CGFloat
    let tinted: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text(snapshot.days == 1 ? "1 DAY" : "\(snapshot.days) DAYS")
                .font(.system(size: clockSize * 0.55, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(tinted ? AnyShapeStyle(.secondary) : AnyShapeStyle(Palette.accentText(scheme)))
                .widgetAccentable()
            clock
                .font(.system(size: clockSize, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// Counts up from the start of the current day of uptime, ticking every second.
    /// The timer drops leading fields ("45:56", "5:12"), so pad it to always read
    /// H:MM:SS; the timeline has entries at the 10- and 60-minute marks to switch.
    private var clock: Text {
        let lap = snapshot.lapElapsed
        let pad = lap < 600 ? "0:0" : lap < 3600 ? "0:" : ""
        return Text("\(pad)\(Text(snapshot.lapStart, style: .timer))")
    }
}

private struct Glow: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        EllipticalGradient(colors: [Palette.cyan.opacity(scheme == .dark ? 0.32 : 0.16), .clear],
                           center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            .scaleEffect(1.35)
    }
}

private struct Header: View {
    let tinted: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "power")
                .font(.system(size: 9, weight: .black))
            Text("UPTIME")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
            Spacer(minLength: 0)
            Circle()
                .fill(tinted ? Color.primary : Palette.live)
                .frame(width: 6, height: 6)
                .shadow(color: Palette.live.opacity(tinted ? 0 : 0.9), radius: 3)
                .widgetAccentable()
        }
        .foregroundStyle(.secondary)
    }
}

private struct Stat: View {
    let label: String
    let value: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            value
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// How much of each of the last seven days the Mac was up.
private struct WeekBars: View {
    @Environment(\.colorScheme) private var scheme
    let days: [UptimeSnapshot.Day]
    let tinted: Bool

    private let barHeight: CGFloat = 30
    private let barWidth: CGFloat = 9

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(days, id: \.start) { day in
                VStack(spacing: 4) {
                    ZStack(alignment: .bottom) {
                        Capsule().fill(.primary.opacity(0.1))
                        if day.upFraction > 0 {
                            Capsule()
                                .fill(tinted ? AnyShapeStyle(.primary) : AnyShapeStyle(Palette.bar))
                                .frame(height: max(barWidth, barHeight * day.upFraction))
                                .widgetAccentable()
                        }
                    }
                    .frame(width: barWidth, height: barHeight)
                    Text(day.start, format: .dateTime.weekday(.narrow))
                        .font(.system(size: 9, weight: day.isToday ? .heavy : .semibold, design: .rounded))
                        .foregroundStyle(day.isToday && !tinted ? AnyShapeStyle(Palette.accentText(scheme)) : AnyShapeStyle(.secondary))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// The widget as a free-standing card, for the app window and previews.
struct UptimeCard: View {
    let snapshot: UptimeSnapshot
    let layout: UptimeLayout
    var tinted = false

    var body: some View {
        UptimeView(snapshot: snapshot, layout: layout, tinted: tinted)
            .padding(16)
            .frame(width: layout == .small ? 164 : 344, height: 164)
            .background { if !tinted { UptimeBackground() } }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
