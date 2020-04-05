//
//  StocksController.swift
//  App
//
//  Created by AlexNerru on 14.03.2020.
//

import Vapor
import Fluent

struct StocksController: RouteCollection {
    static var stocks: [Quote] = []
    
    func boot(router: Router) throws {
        let stocksRouter = router.grouped("stocks")
        
        stocksRouter.get("list", String.parameter, use: getQuotesHandler)
        stocksRouter.get("list", "top", Int.parameter, use: getTopQuotesHandler)
        
        stocksRouter.get("search", String.parameter, use: searchQuotesHandler)
        
        stocksRouter.get("quote", String.parameter, use: getQuoteHandler)
        stocksRouter.get("chart", String.parameter, String.parameter, use: getChartHandler)
    }
    
    static func loadStocks(app: Application) {
        struct Symbol: Content {
            let symbol: String
        }
        
        let symbolsURL = IEXCloud.symbols
            
        let symbols = try? app.client().get(symbolsURL).flatMap {
            try $0.content.decode([Symbol].self)
        }.wait()

        try? stocks = getQuotes(app, symbols: symbols!.map { $0.symbol }).wait()
        
        print("\tLoaded \(stocks.count) quotes")
    }
        
    static func getQuotes(_ con: Container, symbols: [String]) throws -> Future<[Quote]> {
        var quotes: [Quote] = []
            makeBatches(from: symbols, of: 100).forEach { batch in
                usleep(60000)
                try? quotes.append(contentsOf: getQuotes(on: con, batch: batch).wait())
            }
        return con.eventLoop.submit { quotes }
    }
    
    static func makeBatches<T>(from data: [T], of size: Int) -> [[T]] {
        if data.count <= size { return [data] }
        return (0 ... (data.count / size)).map {
            Array(data[$0 * size ... min(($0 + 1) * 100, data.count - 1)])
        }
    }
    
    static func getQuotes(on con: Container, batch: [String]) throws -> Future<[Quote]> {
        if batch.isEmpty { return con.eventLoop.submit { [] } }
        let quotesBatchURL = IEXCloud.quotes(batch: batch)
        return try con.client().get(quotesBatchURL).flatMap { quotes in
            struct Batch: Decodable {
                let quote: Quote
            }
            
            return try quotes.content.decode([String: Batch].self).thenThrowing() {
                return $0.map { $0.value.quote }
            }
        }
    }
    
    func get(period: String) -> IEXCloud.ChartPeriod? {
        switch period {
        case "today":
            return .today
        case "week":
            return .week
        case "month":
            return .month
        case "year":
            return .year
        default:
            return nil
        }
    }
    
    func getTopQuotesHandler(_ req: Request) throws -> Future<[Quote]> {
        let count = try req.parameters.next(Int.self)
        let quotesURL = IEXCloud.quotes(top: count)
        
        return try req.client().get(quotesURL).flatMap {
            try $0.content.decode([Quote].self)
        }
    }
    
    func searchQuotesHandler(_ req: Request) throws -> Future<[Quote]> {
        let searchText = try req.parameters.next(String.self).lowercased()
        let filter: (String) -> Bool = { $0.lowercased().contains(searchText) }

        return Future.flatMap(on: req) {
            let stocks = Self.stocks.filter {
                filter($0.symbol) || filter($0.companyName)
            }
            
            return try! Self.getQuotes(on: req, batch: Array(stocks.map { $0.symbol }
                                                                   .prefix(100)))
        }
    }
    
    func getQuotesHandler(_ req: Request) throws -> Future<[Quote]> {
        let symbols = try req.parameters.next(String.self)
                            .lowercased()
                            .split(separator: ",")
                            .map { String($0) }
        
        return try Self.getQuotes(on: req, batch: symbols)
    }
    
    func getChartHandler(_ req: Request) throws -> Future<[Double]> {
        guard let symbol = try? req.parameters.next(String.self).lowercased(),
            let periodString = try? req.parameters.next(String.self).lowercased(),
            let period = get(period: periodString),
            let chartURL = IEXCloud.chart(for: symbol, period: period) else {
                throw Abort(.badRequest)
        }
                        
        return try req.client().get(chartURL).flatMap { chart in
            return try chart.content.decode(Chart.Data.self).thenThrowing() {
                Chart.process(chart: $0)
            }
        }
    }
    
    func getQuoteHandler(_ req: Request) throws -> Future<Quote> {
        guard let symbol = try? req.parameters.next(String.self).lowercased(),
            let quoteURL = IEXCloud.quote(for: symbol) else {
                throw Abort(.badRequest)
        }
        
        print(quoteURL)
        
        return try req.client().get(quoteURL).flatMap { quote in
            try quote.content.decode(Quote.self)
        }
    }
}
