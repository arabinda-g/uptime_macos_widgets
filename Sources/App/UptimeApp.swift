import SwiftUI
import WidgetKit

@main
struct UptimeApp: App {
    var body: some Scene {
        Window("Uptime", id: "main") {
            VStack(spacing: 18) {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    let snapshot = UptimeSnapshot.current
                    HStack(spacing: 16) {
                        UptimeCard(snapshot: snapshot, layout: .small)
                        UptimeCard(snapshot: snapshot, layout: .medium)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                }

                Text("To put it on your desktop, right-click the desktop, choose Edit Widgets…, and search for “Uptime”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .onAppear { WidgetCenter.shared.reloadAllTimelines() }
        }
        .windowResizability(.contentSize)
    }
}
