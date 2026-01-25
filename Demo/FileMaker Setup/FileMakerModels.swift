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
