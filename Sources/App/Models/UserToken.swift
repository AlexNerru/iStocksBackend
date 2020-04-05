//
//  Token.swift
//  App
//
//  Created by AlexNerru on 13.03.2020.
//

import Authentication
import FluentPostgreSQL

struct UserToken {
    var id: UUID?
    var token: String
    var userID: User.ID

    init(for user: User) throws {
        token = try CryptoRandom().generateData(count: 16).base64EncodedString()
        userID = try user.requireID()
    }
    
    struct Public: Content {
        let token: String
    }
    
    func toPublic() -> Public {
        return Public(token: self.token)
    }
}

extension UserToken: PostgreSQLUUIDModel {}

extension UserToken: Authentication.Token {
    typealias UserType = User
    
    static let tokenKey: TokenKey = \.token
    static let userIDKey: UserIDKey = \.userID
}

extension UserToken: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<()> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Future where T == UserToken {
    func toPublic() -> Future<UserToken.Public> {
        return self.map(to: UserToken.Public.self) { token in
            return token.toPublic()
        }
    }
}

// MARK: - Fluent Relations

extension UserToken {
    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }
}
