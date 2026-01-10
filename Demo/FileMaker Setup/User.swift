//
//  User.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

struct User: Codable {
    let firstName: String
    let lastName: String
    let email: String
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}