//
//  FileMakerConfig.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

struct FileMakerConfig {
    // FileMaker Server Configuration
    static let serverURL = "https://promasidorgh.com"
    
    // Database name - Update this with your FileMaker database file name (without .fmp12 extension)
    // Example: If your file is "MyDatabase.fmp12", use "MyDatabase"
    static let databaseName = "PGH_Item_Distribution" // TODO: Replace with actual database name
    
    // Layout Configuration
    static let layoutName = "test_table_login"
    
    // Application Authentication (for API access)
    static let appUsername = "login"
    static let appPassword = "123456789"
    
    // Table and Field Names
    static let tableName = "TEST_USER_TBL"
    static let emailFieldName = "EmailAddress"
    static let passwordFieldName = "account_password"
    // Note: For sign up, also uses "FirstName" and "LastName" fields
    // Adjust these field names in FileMakerService.createUser if they differ in your database
}
