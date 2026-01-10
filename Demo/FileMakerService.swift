//
//  FileMakerService.swift
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

// MARK: - FileMaker Service
class FileMakerService {
    static let shared = FileMakerService()
    
    private var sessionToken: String?
    private let apiVersion = "vLatest" // or specific version like "v1"
    private let sessionQueue = DispatchQueue(label: "com.filemaker.session")
    
    private init() {}
    
    // MARK: - Authentication
    func authenticate() async throws -> String {
        let databaseName = FileMakerConfig.databaseName
        guard databaseName != "YOUR_DATABASE_NAME" else {
            throw FileMakerError.configurationError("Database name not configured. Please update FileMakerConfig.swift")
        }
        
        // Clear any existing session token before creating a new one
        await clearSession()
        
        let authURL = "\(FileMakerConfig.serverURL)/fmi/data/\(apiVersion)/databases/\(databaseName)/sessions"
        print("🔐 Authenticating with FileMaker Server...")
        print("   URL: \(authURL)")
        
        guard let url = URL(string: authURL) else {
            throw FileMakerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // FileMaker uses Basic Auth for application authentication
        let loginString = "\(FileMakerConfig.appUsername):\(FileMakerConfig.appPassword)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw FileMakerError.encodingError
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.invalidResponse
            }
            
            print("   Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(FileMakerAuthResponse.self, from: data)
                if let token = authResponse.response?.token {
                    self.sessionToken = token
                    print("✅ Authentication successful - Session token received")
                    return token
                } else if let firstMessage = authResponse.messages.first {
                    print("❌ Auth error: [\(firstMessage.code)] \(firstMessage.message)")
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
            } else {
                // Try to parse error message
                if let errorData = try? JSONDecoder().decode(FileMakerAuthResponse.self, from: data),
                   let firstMessage = errorData.messages.first {
                    print("❌ Auth error: [\(firstMessage.code)] \(firstMessage.message)")
                    // Handle capacity error during authentication
                    if firstMessage.code == "812" {
                        await clearSession()
                        throw FileMakerError.capacityExceeded
                    }
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
                print("❌ HTTP error: Status code \(httpResponse.statusCode)")
                throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
            }
            
            throw FileMakerError.authenticationFailed
        } catch let error as FileMakerError {
            throw error
        } catch {
            throw FileMakerError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Find Records (Login)
    func loginUser(email: String, password: String) async throws -> Bool {
        let databaseName = FileMakerConfig.databaseName
        guard databaseName != "YOUR_DATABASE_NAME" else {
            throw FileMakerError.configurationError("Database name not configured. Please update FileMakerConfig.swift")
        }
        
        // Create a session for this login attempt
        // We'll close it immediately after to free up server connections
        var sessionCreated = false
        if sessionToken == nil {
            _ = try await authenticate()
            sessionCreated = true
        }
        
        guard let url = URL(string: "\(FileMakerConfig.serverURL)/fmi/data/\(apiVersion)/databases/\(databaseName)/layouts/\(FileMakerConfig.layoutName)/_find") else {
            throw FileMakerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = sessionToken {
            // FileMaker Data API requires "Bearer" prefix for session token authentication
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create find request - search for matching email and password
        let findQuery: [String: Any] = [
            "query": [
                [
                    FileMakerConfig.emailFieldName: "==\(email)",
                    FileMakerConfig.passwordFieldName: "==\(password)"
                ]
            ],
            "limit": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: findQuery)
        } catch {
            throw FileMakerError.encodingError
        }
        
        do {
            print("🔍 Searching for user in FileMaker database...")
            print("   Find URL: \(url.absoluteString)")
            print("   Using session token: \(sessionToken != nil ? "Yes (length: \(sessionToken?.count ?? 0))" : "No")")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.invalidResponse
            }
            
            print("   Find Response Status: \(httpResponse.statusCode)")
            
            // Log response data for debugging (first 500 chars)
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                let preview = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                print("   Response Body: \(preview)")
            }
            
            if httpResponse.statusCode == 200 {
                let findResponse = try JSONDecoder().decode(FileMakerFindResponse.self, from: data)
                
                if let dataInfo = findResponse.response?.dataInfo,
                   dataInfo.foundCount > 0 {
                    // User found with matching credentials
                    // Close session immediately to free up server connections
                    if sessionCreated {
                        await clearSession()
                    }
                    return true
                } else {
                    // No matching record found - close session
                    print("❌ User not found - No matching record in database")
                    if sessionCreated {
                        await clearSession()
                    }
                    throw FileMakerError.userNotFound
                }
            } else {
                print("❌ Find request failed with status: \(httpResponse.statusCode)")
                
                // Always close session on error
                if sessionCreated {
                    await clearSession()
                }
                
                // Try to parse error message first
                if let errorData = try? JSONDecoder().decode(FileMakerFindResponse.self, from: data),
                   let firstMessage = errorData.messages.first {
                    print("   FileMaker Error: [\(firstMessage.code)] \(firstMessage.message)")
                    // Handle specific error codes
                    if firstMessage.code == "812" {
                        // Exceeded host capacity - this often indicates privilege set connection limits
                        throw FileMakerError.capacityExceeded
                    } else if firstMessage.code == "401" || httpResponse.statusCode == 401 {
                        // Session expired - re-authenticate and retry (but don't create another session if we just created one)
                        // Just throw the error since we already closed the session
                        throw FileMakerError.authenticationFailed
                    }
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
                
                // Handle HTTP status codes
                if httpResponse.statusCode == 401 {
                    print("   HTTP 401 - Authentication failed")
                    throw FileMakerError.authenticationFailed
                }
                
                print("   HTTP Error: \(httpResponse.statusCode)")
                throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
            }
        } catch let error as FileMakerError {
            // Ensure session is closed on any error
            if sessionCreated {
                await clearSession()
            }
            throw error
        } catch {
            // Ensure session is closed on any error
            if sessionCreated {
                await clearSession()
            }
            throw FileMakerError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Session Management
    private func clearSession() async {
        await sessionQueue.sync {
            if let token = sessionToken {
                sessionToken = nil
                // Optionally close the session on server (fire and forget)
                Task {
                    await logoutSession(token: token)
                }
            }
        }
    }
    
    private func logoutSession(token: String) async {
        let databaseName = FileMakerConfig.databaseName
        guard let url = URL(string: "\(FileMakerConfig.serverURL)/fmi/data/\(apiVersion)/databases/\(databaseName)/sessions/\(token)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0 // Short timeout for cleanup
        
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Ignore logout errors - session will timeout on server anyway
        }
    }
    
    // MARK: - Create Record (Sign Up)
    func createUser(firstName: String, lastName: String, email: String, password: String) async throws -> Bool {
        let databaseName = FileMakerConfig.databaseName
        guard databaseName != "YOUR_DATABASE_NAME" else {
            throw FileMakerError.configurationError("Database name not configured. Please update FileMakerConfig.swift")
        }
        
        // Ensure we have a session token
        var sessionCreated = false
        if sessionToken == nil {
            _ = try await authenticate()
            sessionCreated = true
        }
        
        guard let url = URL(string: "\(FileMakerConfig.serverURL)/fmi/data/\(apiVersion)/databases/\(databaseName)/layouts/\(FileMakerConfig.layoutName)/records") else {
            throw FileMakerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create record request
        // Note: You may need to adjust field names (FirstName, LastName) to match your FileMaker database
        let fieldData: [String: Any] = [
            FileMakerConfig.emailFieldName: email,
            FileMakerConfig.passwordFieldName: password,
            "first_name": firstName,
            "last_name": lastName
        ]
        
        let createRequest: [String: Any] = [
            "fieldData": fieldData
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: createRequest)
        } catch {
            throw FileMakerError.encodingError
        }
        
        do {
            print("📝 Creating user record in FileMaker...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.invalidResponse
            }
            
            print("   Create Response Status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                let preview = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                print("   Response Body: \(preview)")
            }
            
            if httpResponse.statusCode == 201 {
                let createResponse = try JSONDecoder().decode(FileMakerCreateResponse.self, from: data)
                
                if createResponse.response?.recordId != nil {
                    print("✅ User record created successfully (Record ID: \(createResponse.response?.recordId ?? "unknown"))")
                    // Close session if we created it
                    if sessionCreated {
                        await clearSession()
                    }
                    return true
                } else if let firstMessage = createResponse.messages.first {
                    print("❌ Create error: [\(firstMessage.code)] \(firstMessage.message)")
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
            } else {
                print("❌ Create request failed with status: \(httpResponse.statusCode)")
                
                // Try to parse error message
                if let errorData = try? JSONDecoder().decode(FileMakerCreateResponse.self, from: data),
                   let firstMessage = errorData.messages.first {
                    print("   FileMaker Error: [\(firstMessage.code)] \(firstMessage.message)")
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
                
                throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
            }
            
            throw FileMakerError.authenticationFailed
        } catch let error as FileMakerError {
            if sessionCreated {
                await clearSession()
            }
            throw error
        } catch {
            if sessionCreated {
                await clearSession()
            }
            throw FileMakerError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Logout
    func logout() async {
        await clearSession()
    }
}

// MARK: - FileMaker Errors
enum FileMakerError: LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case invalidCredentials
    case userNotFound
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
        case .networkError(let message):
            return "Network error: \(message)"
        case .httpError(let statusCode):
            return "Server error (Code: \(statusCode))"
        case .apiError(let code, let message):
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
