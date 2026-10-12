import Foundation
import SwiftUI
import WidgetKit

private let forecastURL = URL(string: "https://codex-reset.com/api/forecast")!
private let sourceURL = URL(string: "https://codex-reset.com/")!
private let resetAccent = Color(red: 242.0 / 255, green: 140.0 / 255, blue: 89.0 / 255)

private struct ForecastResponse: Decodable {
    struct Probabilities: Decodable {
        let rounded24h: Int
        let rounded48h: Int

        enum CodingKeys: String, CodingKey {
            case rounded24h = "rounded_24h"
            case rounded48h = "rounded_48h"
        }
    }

    let updatedAt: String
    let lastResetAt: String
    let confidence: String
    let probabilities: Probabilities

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case lastResetAt = "last_reset_at"
        case confidence
        case probabilities
    }
}

private struct ResetEntry: TimelineEntry, Codable {
    let date: Date
    let updatedAt: Date?
    let lastResetAt: Date?
    let probability24h: Int?
    let probability48h: Int?
    let confidence: String?
    let isOffline: Bool

    static var empty: ResetEntry {
        ResetEntry(date: .now, updatedAt: nil, lastResetAt: nil,
                   probability24h: nil, probability48h: nil,
                   confidence: nil, isOffline: false)
    }
}

private struct ResetProvider: TimelineProvider {
    private let cacheKey = "latestForecast"

    func placeholder(in context: Context) -> ResetEntry { .empty }

    func getSnapshot(in context: Context, completion: @escaping (ResetEntry) -> Void) {
        if context.isPreview {
            completion(.empty)
        } else {
            Task { completion(await loadForecast()) }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ResetEntry>) -> Void) {
        Task {
            let entry = await loadForecast()
            let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1_800)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    private func loadForecast() async -> ResetEntry {
        do {
            var request = URLRequest(url: forecastURL)
            request.timeoutInterval = 10
            request.setValue("CodexResetMacWidget/1.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let forecast = try JSONDecoder().decode(ForecastResponse.self, from: data)
            let entry = ResetEntry(
                date: .now,
                updatedAt: parseDate(forecast.updatedAt),
                lastResetAt: parseDate(forecast.lastResetAt),
                probability24h: forecast.probabilities.rounded24h,
                probability48h: forecast.probabilities.rounded48h,
                confidence: forecast.confidence,
                isOffline: false
            )
            if let cached = try? JSONEncoder().encode(entry) {
                UserDefaults.standard.set(cached, forKey: cacheKey)
            }
            return entry
        } catch {
            if let data = UserDefaults.standard.data(forKey: cacheKey),
               let cached = try? JSONDecoder().decode(ResetEntry.self, from: data) {
                return ResetEntry(date: .now, updatedAt: cached.updatedAt,
                                  lastResetAt: cached.lastResetAt,
                                  probability24h: cached.probability24h,
                                  probability48h: cached.probability48h,
                                  confidence: cached.confidence, isOffline: true)
            }
            return .empty
        }
    }

    private func parseDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: value)
    }
}

private struct ResetWidgetView: View {
    let entry: ResetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            forecast
                .padding(.vertical, 6)
            Divider()
            lastReset
                .padding(.vertical, 5)
            Divider()
            footer
                .padding(.top, 5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .containerBackground(.ultraThinMaterial, for: .widget)
        .widgetURL(sourceURL)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(resetAccent)
            VStack(alignment: .leading, spacing: 0) {
                Text("CODEX RESET")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                Text("GLOBAL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            updateStatus
        }
    }

    private var forecast: some View {
        HStack(spacing: 0) {
            probability(value: entry.probability24h, title: "NEXT 24H")
            metricDivider
            probability(value: entry.probability48h, title: "BY 48H")
            metricDivider
            VStack(alignment: .leading, spacing: 4) {
                Text("CONFIDENCE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                Text(entry.confidence?.capitalized ?? "—")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func probability(value: Int?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
            Text(value.map { "\($0)%" } ?? "—")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 40)
            .padding(.horizontal, 10)
            .accessibilityHidden(true)
    }

    private var lastReset: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Last confirmed")
                .foregroundStyle(.secondary)
            if let date = entry.lastResetAt {
                Text(date, style: .relative)
                    .fontWeight(.medium)
            } else {
                Text("—")
            }
        }
        .font(.system(size: 11))
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }

    private var updateStatus: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.isOffline ? "wifi.slash" : "clock")
            if let updated = entry.updatedAt {
                Text(entry.isOffline ? "Cached" : "Updated")
                Text(updated, style: .relative)
            } else {
                Text(entry.isOffline ? "Offline" : "Waiting for data")
            }
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Text("Experimental model · not a schedule")
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 6)
            Link(destination: sourceURL) {
                Text("Data: codex-reset.com")
                    .lineLimit(1)
            }
            .tint(.secondary)
        }
        .font(.system(size: 9, weight: .regular))
        .foregroundStyle(.secondary)
    }
}

@main
struct CodexResetWidgetBundle: WidgetBundle {
    var body: some Widget {
        CodexResetWidget()
    }
}

private struct CodexResetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CodexResetWidget", provider: ResetProvider()) { entry in
            ResetWidgetView(entry: entry)
        }
        .configurationDisplayName("Codex Reset")
        .description("Medium global reset forecast from codex-reset.com.")
        .supportedFamilies([.systemMedium])
    }
}
