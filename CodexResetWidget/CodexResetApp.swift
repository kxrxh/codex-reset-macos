import SwiftUI
import WidgetKit

private let resetAccent = Color(red: 242.0 / 255, green: 140.0 / 255, blue: 89.0 / 255)

@main
struct CodexResetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 520, height: 370)
        }
        .windowResizability(.contentSize)
    }
}

private struct ContentView: View {
    private let source = URL(string: "https://codex-reset.com/")!

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(resetAccent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Codex Reset")
                        .font(.title.weight(.semibold))
                    Text("Global reset outlook")
                        .foregroundStyle(.secondary)
                }
            }

            Text("See the estimated chance of a global reset in the next 24 and 48 hours. This public historical model does not read your account or personal usage limits.")
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("Refresh widget", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(resetAccent)

                Link(destination: source) {
                    Label("Open data source", systemImage: "arrow.up.right")
                }
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "rectangle.inset.filled")
                    .font(.title3)
                    .foregroundStyle(resetAccent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add the medium widget")
                        .font(.headline)
                    Text("Open Notification Center → Edit Widgets, find Codex Reset, and choose Medium.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Label("Experimental estimate · not a schedule", systemImage: "info.circle")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("The widget requests an update about every 30 minutes; macOS controls the actual refresh timing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(30)
    }
}
