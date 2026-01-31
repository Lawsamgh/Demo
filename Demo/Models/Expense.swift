//
//  Expense.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

struct Expense: Identifiable, Codable {
    let id: String  // FileMaker recordId (PrimaryKey) or UUID string for local
    let title: String
    let amount: Double
    let categoryID: String  // FileMaker Category recordId
    let date: Date
    let type: ExpenseType
    let paymentMethod: String?
    let notes: String?
    /// FileMaker CreationTimestamp; used to sort "recent" (newest first). Falls back to date when nil.
    let creationTimestamp: Date?
    
    init(id: String, title: String, amount: Double, categoryID: String, date: Date, type: ExpenseType, paymentMethod: String? = nil, notes: String? = nil, creationTimestamp: Date? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryID = categoryID
        self.date = date
        self.type = type
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.creationTimestamp = creationTimestamp
    }
    
    /// Sort key for "recent" order: newest first. Uses CreationTimestamp when available, else date.
    var sortDateForRecency: Date {
        creationTimestamp ?? date
    }
}

enum ExpenseType: String, Codable {
    case income = "Income"
    case expense = "Expense"
}

// Legacy enum kept for any fallback display when category is not found
enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case entertainment = "Entertainment"
    case health = "Health"
    case education = "Education"
    case salary = "Salary"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .salary: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "orange"
        case .transport: return "blue"
        case .shopping: return "pink"
        case .bills: return "red"
        case .entertainment: return "purple"
        case .health: return "green"
        case .education: return "indigo"
        case .salary: return "green"
        case .other: return "gray"
        }
    }
}
