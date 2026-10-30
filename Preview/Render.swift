import AppKit
import SwiftUI

// Renders the widget in each appearance on a desktop-like backdrop, so the
// design can be checked without the widget gallery. Uses placeholder data only,
// since the image is published in the README. Usage: Render <output.png>
@main
struct Render {
    @MainActor
    static func main() {
        func row(_ title: String, _ snapshot: UptimeSnapshot, scheme: ColorScheme, tinted: Bool = false) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 16) {
                    UptimeCard(snapshot: snapshot, layout: .small, tinted: tinted)
                    UptimeCard(snapshot: snapshot, layout: .medium, tinted: tinted)
                }
                // Stand-in for the frosted plate macOS puts behind monochrome widgets.
                .background {
                    if tinted {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 24, style: .continuous).frame(width: 164)
                            RoundedRectangle(cornerRadius: 24, style: .continuous).frame(width: 344)
                        }
                        .foregroundStyle(.white.opacity(0.14))
                    }
                }
                .environment(\.colorScheme, scheme)
                .shadow(color: .black.opacity(tinted ? 0 : 0.25), radius: 14, y: 8)
            }
        }

        let sheet = VStack(alignment: .leading, spacing: 22) {
            row("Dark", .sample, scheme: .dark)
            row("Light", .sample, scheme: .light)
            row("Monochrome (desktop behind windows)", .sample, scheme: .dark, tinted: true)
        }
        .padding(28)
        .background(LinearGradient(colors: [Color(hex: 0x3B4B7A), Color(hex: 0x7A5C8F), Color(hex: 0xC98A6B)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))

        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        guard let image = renderer.cgImage else { fatalError("render failed") }
        let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
        try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}
