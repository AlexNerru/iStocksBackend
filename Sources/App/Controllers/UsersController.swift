//
//  UsersController.swift
//  App
//
//  Created by AlexNerru on 13.03.2020.
//

import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        router.grouped("register").post(User.self, use: signUpHandler)
        
        let basicAuth = router.grouped(User.basicAuthMiddleware(using: BCryptDigest()))
        basicAuth.get("login", use: loginHandler)
    }
    
    func signUpHandler(_ req: Request, user: User) throws -> Future<UserToken.Public> {
        let user = try User(username: user.username,
                            password: BCrypt.hash(user.password))
        
        return user.save(on: req).flatMap { user in
            try UserToken(for: user).save(on: req).toPublic()
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<UserToken.Public> {
        let user = try req.requireAuthenticated(User.self)
        
        return try UserToken(for: user).save(on: req).toPublic()
    }
}
