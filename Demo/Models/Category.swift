//
//  Category.swift
//  Demo
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
    
    // Default icon if not provided
    var displayIcon: String {
        icon ?? "ellipsis.circle.fill"
    }
    
    // Default color if not provided
    var displayColor: String {
        color ?? "gray"
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
