//
//  User.swift
//  App
//
//  Created by AlexNerru on 12.03.2020.
//

import Authentication
import FluentPostgreSQL
import Foundation
import Vapor

struct User: Codable {
    var id: UUID?
    
    var username: String
    var password: String
}

extension User: Content {}
extension User: Parameter {}
extension User: PostgreSQLUUIDModel {}

// MARK: - User Uniqueness

extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}

// MARK: - Authentification

extension User: TokenAuthenticatable {
    typealias TokenType = UserToken
}

extension User: PasswordAuthenticatable {
    static var usernameKey: UsernameKey = \.username
    static var passwordKey: PasswordKey = \.password
}

// MARK: - Fluent Relations

extension User {
    var asset: Children<User, Asset> {
        return children(\.userID)
    }
}
