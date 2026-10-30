import AppKit
import SwiftUI

/// The app icon, drawn on Apple's 1024 pt macOS icon grid: an 824 pt rounded
/// square centred in the canvas, so macOS shows it as-is rather than placing
/// it on a plate.
struct AppIconView: View {
    private let corner: CGFloat = 185.4

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x27314F), Color(hex: 0x06080F)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay {
                    EllipticalGradient(colors: [Palette.cyan.opacity(0.38), .clear],
                                       center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                }
                .overlay(alignment: .top) {
                    // Soft sheen across the top half.
                    LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: .center)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.04)],
                                                     startPoint: .top, endPoint: .bottom),
                                      lineWidth: 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .frame(width: 824, height: 824)

            ZStack {
                // Wide blur underneath gives the lit segments a neon bloom.
                HourDial(progress: 0.75, lineWidth: 62, tinted: false)
                    .blur(radius: 22)
                    .opacity(0.9)
                HourDial(progress: 0.75, lineWidth: 62, tinted: false)
            }
            .frame(width: 590, height: 590)

            Image(systemName: "power")
                .font(.system(size: 220, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [.white, Color(hex: 0xBDEFFF)],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: Palette.cyan.opacity(0.7), radius: 18)
        }
        .frame(width: 1024, height: 1024)
        .environment(\.colorScheme, .dark)
    }
}

/// Writes every size an .iconset needs. Usage: AppIcon <dir.iconset> [<preview.png>]
@main
struct RenderIcon {
    @MainActor
    static func main() {
        let args = CommandLine.arguments
        let iconset = URL(fileURLWithPath: args[1])
        try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

        func write(pixels: Int, to url: URL) {
            let renderer = ImageRenderer(content: AppIconView())
            renderer.scale = CGFloat(pixels) / 1024
            guard let image = renderer.cgImage else { fatalError("render failed at \(pixels) px") }
            let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
            try! png.write(to: url)
        }

        for points in [16, 32, 128, 256, 512] {
            write(pixels: points, to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
            write(pixels: points * 2, to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
        }
        if args.count > 2 {
            write(pixels: 512, to: URL(fileURLWithPath: args[2]))
        }
    }
}
