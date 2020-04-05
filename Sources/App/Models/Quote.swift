//
//  Quote.swift
//  App
//
//  Created by AlexNerru on 13.03.2020.
//

import Vapor
import FluentPostgreSQL

struct Quote: Content {
    var symbol: String
    var companyName: String
    
    var latestPrice: Double?
    var change: Double?
    
    var previousVolume: Int?
    var marketCap: Int?
    var week52High: Double?
    var week52Low: Double?
}
