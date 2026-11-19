import Foundation

/// Owns the database work produced by the live market stream away from the
/// SwiftUI main actor. The UI receives one immutable result per batch.
actor MarketStreamDatabaseStore {
    struct RefreshResult: Sendable {
        let holdings: [DatabaseManager.HoldingRecord]
        let portfolioTotals: DatabaseManager.PortfolioTotals
        let allocationRecords: [DatabaseManager.AllocationRecord]
        let todayPLNTD: Double?
    }

    private let databaseManager: DatabaseManager?

    init() {
        databaseManager = try? DatabaseManager()
    }

    func flush(
        ticks: [YahooMarketStream.Tick],
        holdings: [DatabaseManager.HoldingRecord]
    ) -> RefreshResult? {
        guard let databaseManager else { return nil }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        var freshQuotes: [String: MarketDataClient.Quote] = [:]

        for tick in ticks {
            guard let holding = holdings.first(where: { $0.symbol == tick.symbol }) else {
                continue
            }

            do {
                let currency = tick.currency ?? holding.currency
                try databaseManager.insertMarketPrice(
                    symbol: holding.symbol,
                    market: holding.market,
                    price: tick.price,
                    currency: currency,
                    observedAt: timestamp,
                    source: "Yahoo Finance WebSocket"
                )
                if let previousClose = tick.previousClose, previousClose > 0 {
                    try databaseManager.savePreviousClose(
                        symbol: holding.symbol,
                        market: holding.market,
                        price: previousClose,
                        currency: currency,
                        observedAt: timestamp
                    )
                }
                freshQuotes["\(holding.market)|\(holding.symbol)"] = MarketDataClient.Quote(
                    price: tick.price,
                    currency: currency,
                    previousClose: tick.previousClose
                )
            } catch {
                NSLog(
                    "FinTrack WebSocket price update failed for %@: %@", tick.symbol,
                    error.localizedDescription)
            }
        }

        guard !freshQuotes.isEmpty else { return nil }
        let latestHoldings = (try? databaseManager.listHoldings()) ?? holdings
        let todayPLNTD = calculateTodayProfitLoss(
            records: latestHoldings,
            freshQuotes: freshQuotes,
            databaseManager: databaseManager
        )
        let portfolioTotals = (try? databaseManager.portfolioTotals()) ?? DatabaseManager.PortfolioTotals(
            investedNTD: 0,
            marketValueNTD: 0,
            totalPLNTD: 0,
            pricedHoldings: 0
        )
        let allocationRecords = (try? databaseManager.allocationRecords()) ?? []

        return RefreshResult(
            holdings: latestHoldings,
            portfolioTotals: portfolioTotals,
            allocationRecords: allocationRecords,
            todayPLNTD: todayPLNTD
        )
    }

    private func calculateTodayProfitLoss(
        records: [DatabaseManager.HoldingRecord],
        freshQuotes: [String: MarketDataClient.Quote],
        databaseManager: DatabaseManager
    ) -> Double? {
        var dailyPnL = 0.0
        var hasValidResult = false

        for holding in records {
            let key = "\(holding.market)|\(holding.symbol)"
            let quote = freshQuotes[key]
            let currentPrice = quote?.price
                ?? (try? databaseManager.latestMarketPrice(
                    symbol: holding.symbol, market: holding.market))
                ?? 0
            let previousClose = quote?.previousClose
                ?? (try? databaseManager.latestPreviousClose(
                    symbol: holding.symbol, market: holding.market))
                ?? 0
            guard currentPrice > 0, previousClose > 0 else { continue }

            let rate = holding.currency == "NTD"
                ? 1
                : ((try? databaseManager.latestExchangeRate(
                    base: holding.currency, quote: "NTD")) ?? 0)
            guard rate > 0 else { continue }

            dailyPnL += (currentPrice - previousClose) * holding.shares * rate
            hasValidResult = true
        }

        return hasValidResult ? dailyPnL : nil
    }
}
