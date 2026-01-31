//
//  FileMakerModels.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

// MARK: - FileMaker Data Models
struct FileMakerAuthResponse: Codable {
    let response: FileMakerResponse?
    let messages: [FileMakerMessage]
    
    struct FileMakerResponse: Codable {
        let token: String?
    }
    
    struct FileMakerMessage: Codable {
        let code: String
        let message: String
    }
}

struct FileMakerFindResponse: Codable {
    let response: FindResponse?
    let messages: [FileMakerMessage]
    
    struct FindResponse: Codable {
        let dataInfo: DataInfo?
        let data: [RecordData]?
        
        struct DataInfo: Codable {
            let database: String
            let layout: String
            let table: String
            let totalRecordCount: Int
            let foundCount: Int
            let returnedCount: Int
        }
        
        struct RecordData: Codable {
            let fieldData: FieldData
            let recordId: String
            let modId: String
            
            struct FieldData: Codable {
                let EmailAddress: String?
                let account_password: String?
                let first_name: String?
                let last_name: String?
                let Currency: String?
            }
        }
    }
    
    struct FileMakerMessage: Codable {
        let code: String
        let message: String
    }
}

struct FileMakerCreateResponse: Codable {
    let response: CreateResponse?
    let messages: [FileMakerMessage]
    
    struct CreateResponse: Codable {
        let recordId: String
        let modId: String
    }
    
    struct FileMakerMessage: Codable {
        let code: String
        let message: String
    }
}

// MARK: - Expense Find Response (Expenses table)
struct FileMakerExpenseFindResponse: Codable {
    let response: ExpenseFindResponse?
    let messages: [FileMakerMessage]?
    
    struct ExpenseFindResponse: Codable {
        let dataInfo: DataInfo?
        let data: [ExpenseRecordData]?
        
        struct DataInfo: Codable {
            let database: String?
            let layout: String?
            let table: String?
            let totalRecordCount: Int?
            let foundCount: Int?
            let returnedCount: Int?
        }
        
        struct ExpenseRecordData: Codable {
            let fieldData: ExpenseFieldData
            let recordId: String
            let modId: String
            
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                fieldData = try c.decode(ExpenseFieldData.self, forKey: .fieldData)
                // recordId can be number or string from FileMaker
                if let s = try? c.decode(String.self, forKey: .recordId) { recordId = s }
                else if let i = try? c.decode(Int.self, forKey: .recordId) { recordId = String(i) }
                else { recordId = "" }
                modId = (try? c.decode(String.self, forKey: .modId)) ?? (try? c.decode(Int.self, forKey: .modId)).map { String($0) } ?? "0"
            }
            
            enum CodingKeys: String, CodingKey {
                case fieldData, recordId, modId
            }
        }
        
        struct ExpenseFieldData: Codable {
            let UserID: String?
            let Date: String?
            let Amount: String?
            let CategoryID: String?
            let PaymentMethod: String?
            let Description: String?
            let transactionType: String?
            let CreationTimestamp: String?
            
            enum CodingKeys: String, CodingKey {
                case UserID, Date, Amount, CategoryID, PaymentMethod, Description
                case transactionType = "Type"
                case CreationTimestamp
            }
            
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                UserID = try c.decodeIfPresent(String.self, forKey: .UserID)
                Date = try c.decodeIfPresent(String.self, forKey: .Date)
                // FileMaker may return Amount as number or string
                if let d = try? c.decode(Double.self, forKey: .Amount) {
                    Amount = String(d)
                } else if let i = try? c.decode(Int.self, forKey: .Amount) {
                    Amount = String(i)
                } else {
                    Amount = try c.decodeIfPresent(String.self, forKey: .Amount)
                }
                // FileMaker may return CategoryID as number or string (must match Category recordId)
                if let s = try? c.decode(String.self, forKey: .CategoryID) {
                    CategoryID = s
                } else if let i = try? c.decode(Int.self, forKey: .CategoryID) {
                    CategoryID = String(i)
                } else {
                    CategoryID = try c.decodeIfPresent(String.self, forKey: .CategoryID)
                }
                PaymentMethod = try c.decodeIfPresent(String.self, forKey: .PaymentMethod)
                Description = try c.decodeIfPresent(String.self, forKey: .Description)
                transactionType = try c.decodeIfPresent(String.self, forKey: .transactionType)
                CreationTimestamp = try c.decodeIfPresent(String.self, forKey: .CreationTimestamp)
            }
        }
    }
    
    struct FileMakerMessage: Codable {
        let code: String
        let message: String
    }
}

// MARK: - FileMaker Errors
enum FileMakerError: LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case networkError(String)
    case httpError(statusCode: Int)
    case apiError(code: String, message: String)
    case encodingError
    case configurationError(String)
    case capacityExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Failed to authenticate with server"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User does not exist. Please check your email address and try again."
        case .emailAlreadyExists:
            return "This email is already registered. Please use a different email or try signing in."
        case .networkError(let message):
            return "Network error: \(message)"
        case .httpError(let statusCode):
            return "Server error (Code: \(statusCode))"
        case .apiError(let code, let message):
            if code == "0" {
                return "Account successfully created"
            }
            return "FileMaker Error [\(code)]: \(message)"
        case .encodingError:
            return "Failed to encode request data"
        case .configurationError(let message):
            return message
        case .capacityExceeded:
            return "Server is at maximum capacity. Please try again in a moment."
        }
    }
}
