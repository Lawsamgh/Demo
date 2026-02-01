//
//  User.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

struct User: Codable {
    let userID: String // PrimaryKey (recordId) from FileMaker
    let firstName: String
    let lastName: String
    let email: String
    var currency: String? // Preferred currency from FileMaker (test_table_login.Currency)
    var theme: String? // Theme from FileMaker (test_table_login.Theme): "Light Mode" or "Dark Mode"; empty = Light Mode
    var expenseLimitType: String? // "percentage" or "amount"
    var expenseLimitValue: Double? // e.g. 80 for 80%, or 1000 for $1000
    var expenseLimitPeriod: String? // "week", "month", "year"
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    /// User with updated currency (same user, new currency value)
    func withCurrency(_ newCurrency: String?) -> User {
        User(userID: userID, firstName: firstName, lastName: lastName, email: email, currency: newCurrency, theme: theme, expenseLimitType: expenseLimitType, expenseLimitValue: expenseLimitValue, expenseLimitPeriod: expenseLimitPeriod)
    }
    
    /// User with updated theme (same user, new theme value)
    func withTheme(_ newTheme: String?) -> User {
        User(userID: userID, firstName: firstName, lastName: lastName, email: email, currency: currency, theme: newTheme, expenseLimitType: expenseLimitType, expenseLimitValue: expenseLimitValue, expenseLimitPeriod: expenseLimitPeriod)
    }
    
    /// User with updated expense limit settings
    func withExpenseLimit(type: String?, value: Double?, period: String?) -> User {
        User(userID: userID, firstName: firstName, lastName: lastName, email: email, currency: currency, theme: theme, expenseLimitType: type, expenseLimitValue: value, expenseLimitPeriod: period)
    }
    
    init(userID: String, firstName: String, lastName: String, email: String, currency: String? = nil, theme: String? = nil, expenseLimitType: String? = nil, expenseLimitValue: Double? = nil, expenseLimitPeriod: String? = nil) {
        self.userID = userID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.currency = currency
        self.theme = theme
        self.expenseLimitType = expenseLimitType
        self.expenseLimitValue = expenseLimitValue
        self.expenseLimitPeriod = expenseLimitPeriod
    }
}