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
    static let userCurrencyField = "Currency" // Field in test_table_login for preferred currency
    static let userThemeField = "Theme" // Field in test_table_login for theme ("Light Mode" or "Dark Mode")
    static let userExpenseLimitTypeField = "ExpenseLimitType" // "percentage" or "amount"
    static let userExpenseLimitValueField = "ExpenseLimitValue" // e.g. 80 for 80%, or 1000 for $1000
    static let userExpenseLimitPeriodField = "ExpenseLimitPeriod" // "week", "month", "year"
    
    // Category Table Configuration
    static let categoryLayoutName = "Category" // Update with your Category layout name
    static let categoryTableName = "Category" // Update with your Category table name
    static let categoryUserIDField = "UserID" // Field name that stores the user's PrimaryKey
    static let categoryNameField = "CategoryName" // Field name for category name
    static let categoryIconField = "Icon" // Field name for icon (optional)
    static let categoryColorField = "Color" // Field name for color (optional)
    static let categoryIsActiveField = "IsActive" // Field name for active status (optional)
    static let filterByIsActive = true // Set to true if you want to only fetch active categories
    
    // Expenses Table Configuration (FileMaker table: Expenses)
    static let expenseLayoutName = "Expenses" // Layout name for Expenses table
    static let expenseTableName = "Expenses"
    static let expenseUserIDField = "UserID"
    static let expenseDateField = "Date"
    static let expenseAmountField = "Amount"
    static let expenseCategoryIDField = "CategoryID"
    static let expensePaymentMethodField = "PaymentMethod"
    static let expenseDescriptionField = "Description"
    static let expenseTypeField = "Type"
}
