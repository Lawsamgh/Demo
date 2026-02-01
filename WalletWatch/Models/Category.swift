//
//  Category.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

struct Category: Identifiable, Codable {
    let id: String // recordId from FileMaker
    let name: String
    let icon: String?
    let color: String?
    let userID: String
    
    /// SF Symbol names we allow from FileMaker (valid, category-friendly symbols)
    private static let allowedSymbols: Set<String> = [
        "fork.knife", "car.fill", "bag.fill", "doc.text.fill", "tv.fill",
        "heart.fill", "book.fill", "dollarsign.circle.fill", "ellipsis.circle.fill",
        "tag.fill", "house.fill", "cart.fill", "creditcard.fill", "gift.fill",
        "airplane", "bus.fill", "bicycle", "fuelpump.fill", "figure.walk",
        "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill", "wineglass.fill",
        "creditcard", "banknote.fill", "chart.pie.fill", "briefcase.fill",
        "graduationcap.fill", "stethoscope", "pills.fill", "sportscourt.fill",
        "gamecontroller.fill", "film.fill", "music.note", "paintbrush.fill",
        "wrench.and.screwdriver.fill", "hammer.fill", "lightbulb.fill",
        "pawprint.fill", "sparkles", "person.2.fill"
    ]
    
    /// Map keywords in category name to an appropriate SF Symbol
    private static let nameToIcon: [(keywords: [String], icon: String)] = [
        (["food", "groceries", "eating", "restaurant", "dining", "meal", "lunch", "dinner", "breakfast", "cafe", "coffee"], "fork.knife"),
        (["drink", "drinks", "beverage", "bar", "wine", "beer", "coffee", "tea"], "cup.and.saucer.fill"),
        (["transport", "car", "travel", "uber", "taxi", "fuel", "gas", "petrol", "commute"], "car.fill"),
        (["bus", "transit"], "bus.fill"),
        (["flight", "airline", "plane"], "airplane"),
        (["shopping", "store", "retail", "market", "mall"], "bag.fill"),
        (["bills", "utilities", "electric", "water", "rent", "mortgage", "insurance"], "doc.text.fill"),
        (["entertainment", "movie", "cinema", "netflix", "streaming", "game", "gaming"], "tv.fill"),
        (["health", "medical", "pharmacy", "doctor", "fitness", "gym"], "heart.fill"),
        (["education", "school", "course", "training", "book"], "book.fill"),
        (["salary", "income", "pay", "wage", "freelance", "work"], "dollarsign.circle.fill"),
        (["gift", "donation", "charity"], "gift.fill"),
        (["home", "housing", "house"], "house.fill"),
        (["subscription", "membership"], "creditcard.fill"),
        (["pet", "animal", "vet"], "pawprint.fill"),
        (["personal", "care", "beauty"], "sparkles"),
        (["kids", "child", "baby"], "person.2.fill"),
        (["tax"], "doc.text.fill"),
        (["other", "misc", "miscellaneous", "general", "uncategorized"], "tag.fill")
    ]
    
    /// Map keywords in category name to a distinct color
    private static let nameToColor: [(keywords: [String], color: String)] = [
        (["food", "groceries", "eating", "restaurant", "dining", "meal", "lunch", "dinner", "breakfast"], "orange"),
        (["drink", "drinks", "beverage", "bar", "wine", "beer", "coffee", "tea", "cafe"], "brown"),
        (["transport", "car", "travel", "uber", "taxi", "fuel", "gas", "petrol", "commute"], "blue"),
        (["bus", "transit"], "indigo"),
        (["flight", "airline", "plane"], "cyan"),
        (["shopping", "store", "retail", "market", "mall"], "pink"),
        (["bills", "utilities", "electric", "water", "rent", "mortgage", "insurance"], "purple"),
        (["entertainment", "movie", "cinema", "netflix", "streaming", "game", "gaming"], "red"),
        (["health", "medical", "pharmacy", "doctor", "fitness", "gym"], "green"),
        (["education", "school", "course", "training", "book"], "teal"),
        (["salary", "income", "pay", "wage", "freelance", "work"], "mint"),
        (["gift", "donation", "charity"], "yellow"),
        (["home", "housing", "house"], "indigo"),
        (["subscription", "membership"], "purple"),
        (["pet", "animal", "vet"], "orange"),
        (["personal", "care", "beauty"], "pink"),
        (["kids", "child", "baby"], "cyan"),
        (["tax"], "red"),
        (["other", "misc", "miscellaneous", "general", "uncategorized"], "gray")
    ]
    
    /// Palette of distinct colors for fallback assignment by index/hash
    private static let colorPalette: [String] = [
        "blue", "green", "orange", "purple", "pink", "red", "teal", "indigo", "cyan", "mint", "yellow", "brown"
    ]
    
    /// Icon to show in the UI. Uses stored icon if valid, else derives from category name so any category gets an appropriate icon.
    var displayIcon: String {
        let raw = (icon ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if !raw.isEmpty && Self.allowedSymbols.contains(raw) {
            return raw
        }
        return Self.iconForName(name)
    }
    
    /// Returns an SF Symbol for a given name (e.g. "Salary" → "dollarsign.circle.fill"). Used when category is missing so Recent Transactions still show the right icon.
    static func iconForName(_ name: String) -> String {
        let nameLower = name.lowercased()
        for mapping in Self.nameToIcon {
            if mapping.keywords.contains(where: { nameLower.contains($0) }) {
                return mapping.icon
            }
        }
        return "tag.fill"
    }
    
    /// Color to show in the UI. Uses stored color if valid, else derives from category name.
    var displayColor: String {
        // Use stored color if provided and not empty
        if let storedColor = color?.trimmingCharacters(in: .whitespaces).lowercased(),
           !storedColor.isEmpty {
            return storedColor
        }
        // Derive color from category name
        return Self.colorForName(name)
    }
    
    /// Returns a color for a given name (e.g. "Food" → "orange"). Falls back to palette by hash.
    static func colorForName(_ name: String) -> String {
        let nameLower = name.lowercased()
        for mapping in Self.nameToColor {
            if mapping.keywords.contains(where: { nameLower.contains($0) }) {
                return mapping.color
            }
        }
        // Fallback: assign color from palette based on name hash for consistency
        let hash = abs(nameLower.hashValue)
        return colorPalette[hash % colorPalette.count]
    }
}

// MARK: - FileMaker Category Response Model
struct FileMakerCategoryResponse: Codable {
    let response: CategoryFindResponse?
    let messages: [FileMakerMessage]
    
    struct CategoryFindResponse: Codable {
        let dataInfo: DataInfo?
        let data: [CategoryRecordData]?
        
        struct DataInfo: Codable {
            let database: String
            let layout: String
            let table: String
            let totalRecordCount: Int
            let foundCount: Int
            let returnedCount: Int
        }
        
        struct CategoryRecordData: Codable {
            let fieldData: CategoryFieldData
            let recordId: String
            let modId: String
            
            struct CategoryFieldData: Codable {
                // Adjust these field names to match your FileMaker Category table
                // Common variations: CategoryName, category_name, Category_Name, etc.
                let CategoryName: String?
                let category_name: String? // Alternative naming
                let Icon: String?
                let icon: String? // Alternative naming
                let Color: String?
                let color: String? // Alternative naming
                let UserID: String?
                let user_id: String? // Alternative naming
                let User_ID: String? // Alternative naming
                
                // Helper to get category name regardless of field name format
                var resolvedCategoryName: String? {
                    CategoryName ?? category_name
                }
                
                var resolvedIcon: String? {
                    Icon ?? icon
                }
                
                var resolvedColor: String? {
                    Color ?? color
                }
                
                var resolvedUserID: String? {
                    UserID ?? user_id ?? User_ID
                }
            }
        }
    }
    
    struct FileMakerMessage: Codable {
        let code: String
        let message: String
    }
}
