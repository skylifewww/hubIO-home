//
//  UserController.swift
//  hubIO-serverPackageDescription
//
//  Created by Kyle Lee on 1/21/18.
//

import Vapor

internal struct UserController {
    
    private var drop: Droplet
    
    internal init(drop: Droplet) {
        self.drop = drop
    }
    
    internal func addRoutes() {

        let group = drop.grouped("api", "users")
        group.get("usersCount", handler: getAllUsersCount)
        group.post(handler: signUp)
        group.post("signIn", handler: signIn)
        
         let secureGroup = drop.tokenMiddleware.grouped("api", "users")
        secureGroup.get(handler: getAllUsers)
    }
    
    private func getAllUsers(_ request: Request) throws -> ResponseRepresentable {
        let users = try User.all()
        return try users.makeJSON()
    }
    
    private func getAllUsersCount(_ request: Request) throws -> ResponseRepresentable {
        let users = try User.all()
        return "users.count: \(users.count)"
    }
    
    private func signUp(_ request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        
        let user = try User(json: json, drop: drop)
        try user.save()
        
        let token = try AccessToken.generate(for: user)
        print(token.token)
        try token.save()
        
        var responseJSON = JSON()
        try responseJSON.set("user", user.makeJSON())
        try responseJSON.set("token", token.token)

        return responseJSON
    }
    
    private func signIn(_ request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        
        let username: String = try json.get(User.Keys.username)
        let password: String = try json.get(User.Keys.password)
        
        let users = try User.makeQuery().filter(User.Keys.username, username)
        
        // FIND WAY TO MAKE SEARCH CASE INSENSITIVE
        
//        let users = try User.database?.raw("SELECT * FROM `users` WHERE username LIKE '\(username)'")
        
        guard
            let user = try users.first(),
            user.password == password
            else { throw Abort(.badRequest, reason: "Hey dumbass, try again!") }
        
        let token = try AccessToken.generate(for: user)
        print(token.token)
        try token.save()
        
        var responseJSON = JSON()
        try responseJSON.set("user", user.makeJSON())
        try responseJSON.set("token", token.token)
        //invalid username or password
        
        return responseJSON 
    }
    
    
}











