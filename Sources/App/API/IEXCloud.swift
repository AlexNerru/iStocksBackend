//
//  IEXCloud.swift
//  App
//
//  Created by AlexNerru on 12.03.2020.
//

import Foundation

struct IEXCloud {
    private static let api = "https://sandbox.iexapis.com/stable/"
//    private static let api = "https://cloud.iexapi.com/stable/"
    
    private static let token = Token.self
    private static let filter = QuoteFilter.self
    
    private init() { }
    
    static var symbols: URL {
        let queryParameters = "filter=\(filter.basic)&\(token.parameter)"
        
        return URL(string: "\(api)ref-data/symbols?\(queryParameters)")!
    }
        
    static func quotes(top count: Int) -> URL {
        let queryParameters = "filter=\(filter.compact)&listLimit=\(count)&\(token.parameter)"
        let query = "stock/market/list/mostactive"

        return URL(string: "\(api)\(query)?\(queryParameters)")!
    }
    
    static func quotes(batch symbols: [String]) -> URL {
        let symbols = symbols.joined(separator: ",")
                             .filterPathAllowed()
        let queryParameters = "symbols=\(symbols)&types=quote&filter=\(filter.compact)&\(token.parameter)"
                             
        return URL(string: "\(api)stock/market/batch?\(queryParameters)")!
    }
        
    static func quote(for symbol: String) -> URL? {
        let symbol = symbol.filterPathAllowed()
        guard symbol != "" else { return nil }
        
        let queryParameters = "filter=\(filter.extended)&\(token.parameter)"
        
        return URL(string: "\(api)stock/\(symbol)/quote/?\(queryParameters)")
    }
    
    static func chart(for symbol: String, period: ChartPeriod) -> URL? {
        let symbol = symbol.filterPathAllowed()
        guard symbol != "" else { return nil }
        
        let queryParameters = "filter=\(filter.chart)&\(token.parameter)"
        let query = "stock/\(symbol)/chart/\(period)"
        
        return URL(string: "\(api)\(query)?\(queryParameters)")
    }
    
    static func chart(batch symbols: [String], period: ChartPeriod) -> URL? {
        let symbols = symbols.filterPathAllowed()
                             .joined(separator: ",")
        guard symbols != "" else { return nil }
        
        let queryParameters = "symbols=\(symbols)&types=chart&filter=\(filter.chart)&\(token.parameter)"
        let query = "\(api)stock/market/batch/\(period)?\(queryParameters)"
        print(query)
        return URL(string: query)
    }
    
    private struct QuoteFilter {
        static let basic = "symbol,companyName"
        static let compact = "\(basic),latestPrice,change"
        static let extended = "\(compact),low,latestVolume,previousVolume,marketCap,week52Low,week52High"
        static let chart = "low,high"
        
        private init() { }
    }
    
    private struct Token {
        private static let token = "Tsk_6d5c8f54bf934487935ce6335356bcff"
//        private static let token = "pk_3cdc6273fb9f4281b46c854ec750cd97"
        private init() { }
        
        static var parameter: String {
            "token=\(token)"
        }
    }
    
    enum ChartPeriod: String, CustomStringConvertible {
        case today
        case week = "5d"
        case month = "1m"
        case year = "1y"
        
        var description: String {
            self == .today ? "date/\(today)" : self.rawValue
        }
        
        private var today: String {
            let df = DateFormatter()
            df.dateFormat = "YYYYMMdd"
            return df.string(from: Date())
        }
    }
}

fileprivate extension String {
    func filterPathAllowed() -> String {
        self.filter { !$0.unicodeScalars.contains(where: {
            !CharacterSet.urlPathAllowed.contains($0)
        })}
    }
}

fileprivate extension Array where Element == String {
    func filterPathAllowed() -> [String] {
        self.compactMap {
            let element = $0.filterPathAllowed()
            return !element.isEmpty ? element : nil
        }
    }
}

