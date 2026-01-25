//
//  FileMakerRequestBuilder.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

/// Helper for building FileMaker API requests
struct FileMakerRequestBuilder {
    private let apiVersion = "vLatest"
    
    /// Builds a URL for a FileMaker API endpoint
    func buildURL(endpoint: String) throws -> URL {
        let databaseName = FileMakerConfig.databaseName
        guard databaseName != "YOUR_DATABASE_NAME" else {
            throw FileMakerError.configurationError("Database name not configured. Please update FileMakerConfig.swift")
        }
        
        let urlString = "\(FileMakerConfig.serverURL)/fmi/data/\(apiVersion)/databases/\(databaseName)/\(endpoint)"
        guard let url = URL(string: urlString) else {
            throw FileMakerError.invalidURL
        }
        return url
    }
    
    /// Creates a request with session token authentication
    func createRequest(url: URL, method: String, body: Data? = nil, sessionToken: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        return request
    }
    
    /// Creates a find query request body
    func createFindQuery(fields: [String: String], limit: Int = 1) throws -> Data {
        let query: [String: Any] = [
            "query": [fields],
            "limit": limit
        ]
        return try JSONSerialization.data(withJSONObject: query)
    }
    
    /// Creates a create record request body
    func createRecordBody(fieldData: [String: Any]) throws -> Data {
        let request: [String: Any] = ["fieldData": fieldData]
        return try JSONSerialization.data(withJSONObject: request)
    }
}
