//
//  AssetsController.swift
//  App
//
//  Created by AlexNerru on 14.03.2020.
//

import Vapor
import Fluent

struct AssetsController: RouteCollection {
    var stocksController: StocksController
    
    func boot(router: Router) throws {
        let router = router.grouped("assets")
    
        let tokenGroup = router.grouped(User.tokenAuthMiddleware(),
                                        User.guardAuthMiddleware())
        
        tokenGroup.get(use: getAssetsHandler)
        tokenGroup.post([Asset.Public].self, use: addAssetsHandler)
        tokenGroup.delete(UUID.parameter, use: deleteAssetHandler)
        
        tokenGroup.get("chart", String.parameter, use: getChartHandler)
        
        tokenGroup.grouped("addExample").get() { req throws ->  Future<Asset.Public> in
            let user = try req.requireAuthenticated(User.self)
            
            return try Asset(Asset.Public(id: UUID(),
                                   quote: Quote(symbol: "AAPL",
                                                companyName: "Apple.inc"),
                                   date: Date(),
                                   price: 123),
                  userID: user.requireID()).save(on: req).map {
                    Asset.Public(id: $0.id!, quote: $0.quote, date: $0.date, price: $0.price)
            }
        }
    }
    
    
    
    func getAssetsHandler(_ req: Request) throws -> Future<[Asset.Public]> {
        let user = try req.requireAuthenticated(User.self)
        
        return try user.asset.query(on: req).all().toPublic()
    }
    
    func addAssetsHandler(_ req: Request, assets: [Asset.Public]) throws -> Future<[Asset.Public]> {
        let user = try req.requireAuthenticated(User.self)
        
        let assets = try assets.map { try Asset($0, userID: user.requireID()) }
        return assets.map { $0.save(on: req) }
                     .flatten(on: req)
                     .transform(to: [])
    }
    
    func deleteAssetHandler(_ req: Request) throws -> Future<[Asset.Public]> {
        let user = try req.requireAuthenticated(User.self)
        print("[ DELETION ]")
        
        let id = try req.parameters.next(UUID.self)
        print(id)
        return try user.asset.query(on: req)
                             .filter(\.id == id)
                             .delete()
                             .transform(to: [])
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
    
    func getChartHandler(_ req: Request) throws -> Future<[Double]> {
        let user = try req.requireAuthenticated(User.self)

        return try user.asset.query(on: req).all().map {
            return $0.countOcurences(keyPath: \.quote.symbol)
        }.flatMap { countSymbols in
            let symbols = Array(countSymbols.keys)

            guard let periodString = try? req.parameters.next(String.self).lowercased(),
                let period = self.get(period: periodString),
                let chartURL = IEXCloud.chart(batch: symbols, period: period) else {
                    throw Abort(.badRequest)
            }
            
            return try req.client().get(chartURL).flatMap { chart in
                return try chart.content.decode([String: [String: Chart.Data]].self).thenThrowing() {
                    let charts = $0.compactMap { symbol, chart in (chart.values.flatMap { $0 }, countSymbols[symbol]!) }
                    return Chart.process(charts: charts)
                }
            }
        }
    }
}

fileprivate extension Array {
    func countOcurences<Key: Hashable>(keyPath: KeyPath<Element, Key>) -> [Key: Int] {
        self.reduce(into: [:]) {
            $0[$1[keyPath: keyPath]] = ($0[$1[keyPath: keyPath]] ?? 0) + 1
        }
    }
}
