//
//  Asset.swift
//  App
//
//  Created by AlexNerru on 13.03.2020.
//

import Vapor
import FluentPostgreSQL

struct Asset {
    var id: UUID?
    
    var quote: Quote
    var date: Date
    var price: Double

    var userID: User.ID
        
    
    struct Public: Content {
        let id: UUID
        let quote: Quote
        let date: Date
        let price: Double
    }
    
    init(_ publicAsset: Public, userID: User.ID) {
        self.quote = publicAsset.quote
        self.date = publicAsset.date
        self.price = publicAsset.price
        self.userID = userID
    }
    
    func toPublic() -> Public {
        return Public(id: id!, quote: quote, date: date, price: price)
    }
}

extension Asset: Parameter {}
extension Asset: PostgreSQLUUIDModel {}
extension Asset: Migration {}

extension Future where T == [Asset] {
    func toPublic() -> Future<[Asset.Public]> {
        return self.map { $0.map { $0.toPublic() } }
    }
}

// MARK: - Fluent Relations

extension Asset {
    var user: Parent<Asset, User> {
        return parent(\.userID)
    }
}
