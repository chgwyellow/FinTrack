import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var databaseManager: DatabaseManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--fintrack-snapshot") {
            SnapshotBackgroundAgent.run()
            NSApp.terminate(nil)
            return
        }
        if CommandLine.arguments.contains("--fintrack-today-baseline") {
            Task {
                await TodayBaselineBackgroundAgent.run()
                NSApp.terminate(nil)
            }
            return
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        initializeDatabase()
        SnapshotScheduler.install()
        configureWindows()
    }

    private func initializeDatabase() {
        do {
            databaseManager = try DatabaseManager()
        } catch {
            NSLog("FinTrack database initialization failed: %@", error.localizedDescription)
        }
    }

    private func configureWindows() {
        for window in NSApp.windows {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }
    }
}

private enum SnapshotBackgroundAgent {
    static func run() {
        do {
            let databaseManager = try DatabaseManager()
            let dateString = previousSnapshotDateString(for: Date())
            try databaseManager.saveSnapshot(
                date: dateString,
                assets: try databaseManager.assetTotals(),
                liabilities: try databaseManager.liabilityTotals(),
                detailValues: (try? databaseManager.snapshotDetailValues()) ?? [:]
            )
            UserDefaults.standard.set(dateString, forKey: automaticSnapshotDateKey)
        } catch {
            NSLog("FinTrack background snapshot failed: %@", error.localizedDescription)
        }
    }
}

private enum TodayBaselineBackgroundAgent {
    static func run() async {
        do {
            let databaseManager = try DatabaseManager()
            let holdings = try databaseManager.listHoldings()
            let client = MarketDataClient()
            var quotes: [(DatabaseManager.HoldingRecord, MarketDataClient.Quote)] = []
            for holding in holdings {
                if let quote = try await client.fetchQuote(symbol: holding.symbol) {
                    quotes.append((holding, quote))
                }
            }
            guard quotes.count == holdings.count, !holdings.isEmpty else { return }

            for currency in Set(holdings.map(\.currency)).filter({ $0 != "NTD" }) {
                if let rate = try await client.fetchExchangeRate(baseCurrency: currency) {
                    try databaseManager.insertExchangeRate(
                        base: currency, quote: "NTD", rate: rate,
                        observedAt: ISO8601DateFormatter().string(from: Date()),
                        source: "ExchangeRate-API"
                    )
                }
            }
            var baselineValue = 0.0
            for (holding, quote) in quotes {
                guard let previousClose = quote.previousClose else { return }
                let rate =
                    holding.currency == "NTD"
                    ? 1
                    : ((try databaseManager.latestExchangeRate(base: holding.currency, quote: "NTD"))
                        ?? 0)
                guard rate > 0 else { return }
                baselineValue += previousClose * holding.shares * rate
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            try databaseManager.savePortfolioDailyBaseline(
                date: formatter.string(from: Date()), marketValueNTD: baselineValue
            )
        } catch {
            NSLog("FinTrack TODAY baseline failed: %@", error.localizedDescription)
        }
    }
}

enum SnapshotScheduler {
    private static let label = "com.fintrack.snapshot"
    private static let todayBaselineLabel = "com.fintrack.today-baseline"

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    static func install() {
        let applicationPath = Bundle.main.bundleURL.path
        let configuredTime = UserDefaults.standard.string(forKey: "snapshotTime") ?? "23:00"
        let components = configuredTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2,
            (0...23).contains(components[0]),
            (0...59).contains(components[1])
        else { return }

        let launchAgent: [String: Any] = [
            "Label": label,
            "ProgramArguments": [
                "/usr/bin/open", "-a", applicationPath, "--args", "--fintrack-snapshot",
            ],
            "StartCalendarInterval": [
                "Hour": components[0],
                "Minute": components[1],
            ],
            "ProcessType": "Background",
            "RunAtLoad": false,
        ]

        do {
            let directoryURL = launchAgentURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(
                fromPropertyList: launchAgent,
                format: .xml,
                options: 0
            )
            let domain = "gui/\(getuid())"
            installAgent(
                data: data,
                url: launchAgentURL,
                label: label,
                domain: domain
            )
            installTodayBaselineAgent(applicationPath: applicationPath, domain: domain)
        } catch {
            NSLog("FinTrack snapshot scheduler setup failed: %@", error.localizedDescription)
        }
    }

    private static func installTodayBaselineAgent(applicationPath: String, domain: String) {
        let url = launchAgentURL.deletingLastPathComponent().appendingPathComponent(
            "com.fintrack.today-baseline.plist")
        let agent: [String: Any] = [
            "Label": todayBaselineLabel,
            "ProgramArguments": [
                "/usr/bin/open", "-a", applicationPath, "--args", "--fintrack-today-baseline",
            ],
            "StartCalendarInterval": ["Hour": 8, "Minute": 0],
            "ProcessType": "Background",
            "RunAtLoad": false,
        ]
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: agent, format: .xml, options: 0)
            installAgent(data: data, url: url, label: todayBaselineLabel, domain: domain)
        } catch {
            NSLog("FinTrack TODAY scheduler setup failed: %@", error.localizedDescription)
        }
    }

    private static func installAgent(data: Data, url: URL, label: String, domain: String) {
        let existingData = try? Data(contentsOf: url)
        let isLoaded = runLaunchctl(["print", "\(domain)/\(label)"]) == 0
        do {
            try data.write(to: url, options: .atomic)
            guard existingData != data || !isLoaded else { return }
            runLaunchctl(["bootout", domain, url.path])
            runLaunchctl(["bootstrap", domain, url.path])
        } catch {
            NSLog("FinTrack scheduler file write failed: %@", error.localizedDescription)
        }
    }

    @discardableResult
    private static func runLaunchctl(_ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            NSLog("FinTrack launchctl failed: %@", error.localizedDescription)
            return -1
        }
    }
}
