import SwiftUI
import WidgetKit

extension UptimeSnapshot: TimelineEntry {}

struct UptimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> UptimeSnapshot {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (UptimeSnapshot) -> Void) {
        completion(.current)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UptimeSnapshot>) -> Void) {
        // The clock ticks on its own; these entries move the dial and bars along
        // every 5 minutes for the next 2 hours.
        let entries = UptimeSnapshot.timeline(count: 24, every: 5 * 60)
        // Reload well before they run out, mainly so a reboot is picked up.
        completion(Timeline(entries: entries, policy: .after(.now.addingTimeInterval(30 * 60))))
    }
}

struct UptimeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: UptimeSnapshot

    var body: some View {
        UptimeView(snapshot: entry,
                   layout: family == .systemSmall ? .small : .medium,
                   tinted: renderingMode != .fullColor)
            .containerBackground(for: .widget) { UptimeBackground() }
    }
}

struct UptimeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UptimeWidget", provider: UptimeProvider()) { entry in
            UptimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Uptime")
        .description("Time since this Mac last booted.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct UptimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        UptimeWidget()
    }
}
