//
//  FileMakerSessionManager.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

/// Manages FileMaker API session tokens (thread-safe)
class FileMakerSessionManager {
    static let shared = FileMakerSessionManager()
    
    private var sessionToken: String?
    private let sessionQueue = DispatchQueue(label: "com.filemaker.session")
    
    private init() {}
    
    var token: String? {
        sessionQueue.sync {
            sessionToken
        }
    }
    
    func setToken(_ token: String) {
        sessionQueue.sync { [weak self] in
            self?.sessionToken = token
        }
    }
    
    func clearToken() {
        sessionQueue.sync { [weak self] in
            self?.sessionToken = nil
        }
    }
    
    func hasToken() -> Bool {
        sessionQueue.sync {
            sessionToken != nil
        }
    }
}
