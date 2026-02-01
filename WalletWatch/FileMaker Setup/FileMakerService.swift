//
//  FileMakerService.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation

// MARK: - FileMaker Service
class FileMakerService {
    static let shared = FileMakerService()
    
    private let sessionManager = FileMakerSessionManager.shared
    private let requestBuilder = FileMakerRequestBuilder()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Authenticates and returns a session token
    func authenticate() async throws -> String {
        sessionManager.clearToken()
        return try await createNewSession()
    }
    
    /// Creates a new FileMaker session
    private func createNewSession() async throws -> String {
        let databaseName = FileMakerConfig.databaseName
        guard databaseName != "YOUR_DATABASE_NAME" else {
            throw FileMakerError.configurationError("Database name not configured. Please update FileMakerConfig.swift")
        }
        
        let authURL = "\(FileMakerConfig.serverURL)/fmi/data/vLatest/databases/\(databaseName)/sessions"
        print("🔐 Authenticating with FileMaker Server...")
        print("   URL: \(authURL)")
        
        guard let url = URL(string: authURL) else {
            throw FileMakerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Basic Auth for application authentication
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
                    sessionManager.setToken(token)
                    print("✅ Authentication successful - Session token received")
                    return token
                } else if let firstMessage = authResponse.messages.first {
                    print("❌ Auth error: [\(firstMessage.code)] \(firstMessage.message)")
                    if firstMessage.code == "812" {
                        throw FileMakerError.capacityExceeded
                    }
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
            } else {
                if let errorData = try? JSONDecoder().decode(FileMakerAuthResponse.self, from: data),
                   let firstMessage = errorData.messages.first {
                    print("❌ Auth error: [\(firstMessage.code)] \(firstMessage.message)")
                    if firstMessage.code == "812" {
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
        } catch let urlError as URLError {
            // Provide more detailed error information
            print("❌ URL Error during authentication:")
            print("   Error Code: \(urlError.code.rawValue)")
            print("   Error Description: \(urlError.localizedDescription)")
            if let failureURL = urlError.failureURLString {
                print("   Failure URL: \(failureURL)")
            }
            throw FileMakerError.networkError("\(urlError.localizedDescription) (Code: \(urlError.code.rawValue))")
        } catch {
            // Re-throw network errors with more context
            print("❌ Network error during authentication: \(error.localizedDescription)")
            print("   Error Type: \(type(of: error))")
            throw FileMakerError.networkError(error.localizedDescription)
        }
    }
    
    /// Logs in a user with email and password
    func loginUser(email: String, password: String) async throws -> User {
        return try await withSession { token in
            try await self.performLogin(email: email, password: password, token: token)
        }
    }
    
    /// Fetches categories for a specific user from FileMaker
    func fetchCategories(userID: String) async throws -> [Category] {
        return try await withSession { token in
            try await self.performFetchCategories(userID: userID, token: token)
        }
    }
    
    /// Creates a new category in FileMaker for the given user
    func createCategory(userID: String, name: String) async throws -> String {
        return try await withSession { token in
            try await self.performCreateCategory(userID: userID, name: name, token: token)
        }
    }
    
    /// Updates an existing category in FileMaker (name only)
    func updateCategory(recordId: String, name: String) async throws {
        return try await withSession { token in
            try await self.performUpdateCategory(recordId: recordId, name: name, token: token)
        }
    }
    
    /// Checks if an email already exists in the database
    func emailExists(_ email: String) async throws -> Bool {
        return try await withSession { token in
            try await self.checkEmailExists(email: email, token: token)
        }
    }
    
    /// Creates a new user account
    func createUser(firstName: String, lastName: String, email: String, password: String) async throws -> Bool {
        // Check if email already exists
        print("🔍 Checking if email already exists...")
        let exists = try await emailExists(email)
        if exists {
            print("❌ Email already exists: \(email)")
            throw FileMakerError.emailAlreadyExists
        }
        
        return try await withSession { token in
            try await self.performCreateUser(firstName: firstName, lastName: lastName, email: email, password: password, token: token)
        }
    }
    
    /// Creates a new expense/transaction record in FileMaker
    func createExpense(userID: String, date: Date, amount: Double, categoryID: String, paymentMethod: String, description: String, type: ExpenseType) async throws -> String {
        return try await withSession { token in
            try await self.performCreateExpense(userID: userID, date: date, amount: amount, categoryID: categoryID, paymentMethod: paymentMethod, description: description, type: type, token: token)
        }
    }
    
    /// Fetches expenses for a specific user from FileMaker
    func fetchExpenses(userID: String) async throws -> [Expense] {
        return try await withSession { token in
            try await self.performFetchExpenses(userID: userID, token: token)
        }
    }
    
    /// Updates the user's Theme field in FileMaker (test_table_login.Theme)
    func updateUserTheme(userID: String, theme: String) async throws {
        return try await withSession { token in
            try await self.performUpdateUserTheme(userID: userID, theme: theme, token: token)
        }
    }
    
    /// Updates the user's preferred currency in FileMaker (test_table_login.Currency)
    func updateUserCurrency(userID: String, currency: String) async throws {
        return try await withSession { token in
            try await self.performUpdateUserCurrency(userID: userID, currency: currency, token: token)
        }
    }
    
    /// Updates the user's expense limit in FileMaker (test_table_login)
    func updateUserExpenseLimit(userID: String, type: String, value: Double, period: String) async throws {
        return try await withSession { token in
            try await self.performUpdateUserExpenseLimit(userID: userID, type: type, value: value, period: period, token: token)
        }
    }
    
    /// Updates the user's password in FileMaker (test_table_login.account_password)
    func updateUserPassword(userID: String, newPassword: String) async throws {
        return try await withSession { token in
            try await self.performUpdateUserPassword(userID: userID, newPassword: newPassword, token: token)
        }
    }
    
    /// Logs out and clears the session
    func logout() async {
        if let token = sessionManager.token {
            await closeSessionOnServer(token: token)
        }
    }
    
    // MARK: - Private Implementation
    
    /// Executes a block with a valid session, ensuring cleanup
    private func withSession<T>(_ operation: @escaping (String) async throws -> T) async throws -> T {
        // Check if we already have a session
        let hadToken = sessionManager.hasToken()
        let token: String
        
        if hadToken, let existingToken = sessionManager.token {
            token = existingToken
        } else {
            // Create new session
            token = try await createNewSession()
        }
        
        let sessionWasCreated = !hadToken
        
        do {
            let result = try await operation(token)
            // Only close session if we created it for this operation
            if sessionWasCreated {
                await closeSessionOnServer(token: token)
            }
            return result
        } catch {
            // Always close session on error if we created it
            if sessionWasCreated {
                await closeSessionOnServer(token: token)
            }
            throw error
        }
    }
    
    /// Closes the session on the server
    private func closeSessionOnServer(token: String) async {
        let databaseName = FileMakerConfig.databaseName
        guard let url = URL(string: "\(FileMakerConfig.serverURL)/fmi/data/vLatest/databases/\(databaseName)/sessions/\(token)") else {
            sessionManager.clearToken()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0
        
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Ignore logout errors - session will timeout on server anyway
        }
        
        sessionManager.clearToken()
    }
    
    /// Performs the actual login operation
    private func performLogin(email: String, password: String, token: String) async throws -> User {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/_find"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fields = [
            FileMakerConfig.emailFieldName: "==\(email)",
            FileMakerConfig.passwordFieldName: "==\(password)"
        ]
        let body = try requestBuilder.createFindQuery(fields: fields)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        print("🔍 Searching for user in FileMaker database...")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        print("   Find Response Status: \(httpResponse.statusCode)")
        logResponse(data: data)
        
        if httpResponse.statusCode == 200 {
            let findResponse = try JSONDecoder().decode(FileMakerFindResponse.self, from: data)
            
            guard let dataInfo = findResponse.response?.dataInfo,
                  dataInfo.foundCount > 0,
                  let userData = findResponse.response?.data?.first else {
                print("❌ User not found - No matching record in database")
                throw FileMakerError.userNotFound
            }
            
            let firstName = userData.fieldData.first_name ?? ""
            let lastName = userData.fieldData.last_name ?? ""
            let userID = userData.recordId // Get the PrimaryKey (recordId)
            let currency = userData.fieldData.Currency?.trimmingCharacters(in: .whitespaces).isEmpty == false ? userData.fieldData.Currency : nil
            // Theme: "Light Mode" or "Dark Mode"; empty defaults to Light Mode
            let themeRaw = userData.fieldData.Theme?.trimmingCharacters(in: .whitespaces)
            let theme: String? = (themeRaw?.isEmpty == false) ? themeRaw : nil
            // Expense limit: type (percentage/amount), value, period (week/month/year)
            let limitTypeRaw = userData.fieldData.ExpenseLimitType?.trimmingCharacters(in: .whitespaces).lowercased()
            let expenseLimitType: String? = (limitTypeRaw == "percentage" || limitTypeRaw == "amount") ? limitTypeRaw : nil
            let expenseLimitValue: Double? = userData.fieldData.ExpenseLimitValue
            let limitPeriodRaw = userData.fieldData.ExpenseLimitPeriod?.trimmingCharacters(in: .whitespaces).lowercased()
            let expenseLimitPeriod: String? = (limitPeriodRaw == "week" || limitPeriodRaw == "month" || limitPeriodRaw == "year") ? limitPeriodRaw : nil
            print("✅ Login successful!")
            print("📋 PrimaryKey (recordId) from test_table_login: '\(userID)'")
            print("📋 PrimaryKey type: \(type(of: userID))")
            print("📋 This PrimaryKey will be used to filter Category table by UserID field")
            return User(userID: userID, firstName: firstName, lastName: lastName, email: email, currency: currency, theme: theme, expenseLimitType: expenseLimitType, expenseLimitValue: expenseLimitValue, expenseLimitPeriod: expenseLimitPeriod)
        } else {
            try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
            throw FileMakerError.userNotFound
        }
    }
    
    /// Creates a category record in FileMaker
    private func performCreateCategory(userID: String, name: String, token: String) async throws -> String {
        let endpoint = "layouts/\(FileMakerConfig.categoryLayoutName)/records"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.categoryUserIDField: userID,
            FileMakerConfig.categoryNameField: name,
            FileMakerConfig.categoryIsActiveField: "1"
        ]
        
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        if let bodyJson = String(data: body, encoding: .utf8) {
            print("📝 Create category request fieldData: \(bodyJson)")
        }
        print("📝 Creating category in FileMaker: \(name)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let createResponse = try JSONDecoder().decode(FileMakerCreateResponse.self, from: data)
            if let recordId = createResponse.response?.recordId {
                print("✅ Category created: \(recordId)")
                return recordId
            }
            if let firstMessage = createResponse.messages.first, firstMessage.code != "0" {
                throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
            }
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.invalidResponse
    }
    
    /// Updates a category record in FileMaker (PATCH by recordId)
    private func performUpdateCategory(recordId: String, name: String, token: String) async throws {
        let endpoint = "layouts/\(FileMakerConfig.categoryLayoutName)/records/\(recordId)"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.categoryNameField: name
        ]
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "PATCH", body: body, sessionToken: token)
        
        print("📝 Updating category in FileMaker: \(recordId) -> \(name)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Category updated successfully")
            return
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    /// Fetches categories from FileMaker for a specific user
    private func performFetchCategories(userID: String, token: String) async throws -> [Category] {
        let endpoint = "layouts/\(FileMakerConfig.categoryLayoutName)/_find"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        print("============================================================")
        print("🔍 FETCHING CATEGORIES - DEBUG INFO")
        print("============================================================")
        print("📋 PrimaryKey from test_table_login: '\(userID)'")
        print("📋 PrimaryKey type: String")
        print("📋 Category Layout: \(FileMakerConfig.categoryLayoutName)")
        print("📋 Category UserID Field: \(FileMakerConfig.categoryUserIDField)")
        print("📋 This PrimaryKey will be used to filter Category.UserID field")
        print("============================================================")
        
        // Try multiple query formats to handle different field types
        // Format 1: Try as string with == operator (for text fields)
        var queryFields: [String: Any] = [:]
        
        // UserID field - try as string first (most common for foreign keys)
        queryFields[FileMakerConfig.categoryUserIDField] = "==\(userID)"
        print("📤 Trying UserID as string: '==\(userID)'")
        
        // Add IsActive filter if configured
        if FileMakerConfig.filterByIsActive {
            queryFields[FileMakerConfig.categoryIsActiveField] = "==1" // Try as string first
            print("📤 Trying IsActive as string: '==1'")
        }
        
        let body = try requestBuilder.createFindQueryWithFields(fields: queryFields, limit: 100)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        // Log the request body for debugging
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Full Category Query JSON: \(bodyString)")
        }
        
        print("🔍 Sending request to FileMaker...")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        print("   Category Response Status: \(httpResponse.statusCode)")
        logResponse(data: data)
        
        if httpResponse.statusCode == 200 {
            let categoryResponse = try JSONDecoder().decode(FileMakerCategoryResponse.self, from: data)
            
            guard categoryResponse.response?.dataInfo != nil,
                  let categoryRecords = categoryResponse.response?.data else {
                print("⚠️ No categories found for user")
                return []
            }
            
            print("✅ Found \(categoryRecords.count) categories")
            
            // Convert FileMaker records to Category objects
            let categories = categoryRecords.compactMap { record -> Category? in
                guard let categoryName = record.fieldData.resolvedCategoryName,
                      !categoryName.isEmpty else {
                    print("⚠️ Skipping category record: Missing category name")
                    return nil
                }
                
                return Category(
                    id: record.recordId,
                    name: categoryName,
                    icon: record.fieldData.resolvedIcon,
                    color: record.fieldData.resolvedColor,
                    userID: userID
                )
            }
            
            return categories
        } else {
            // Error 401 means "No records match the request" - return empty array
            if let errorData = try? JSONDecoder().decode(FileMakerCategoryResponse.self, from: data),
               let firstMessage = errorData.messages.first,
               firstMessage.code == "401" {
                print("   ✅ No categories found (no matching records)")
                return []
            }
            
            try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
            throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Checks if an email exists
    private func checkEmailExists(email: String, token: String) async throws -> Bool {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/_find"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fields = [FileMakerConfig.emailFieldName: "==\(email)"]
        let body = try requestBuilder.createFindQuery(fields: fields)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        print("🔍 Checking if email exists: \(email)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        print("   Check Response Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            let findResponse = try JSONDecoder().decode(FileMakerFindResponse.self, from: data)
            
            if let dataInfo = findResponse.response?.dataInfo,
               dataInfo.foundCount > 0 {
                print("   ⚠️ Email already exists")
                return true
            } else {
                print("   ✅ Email is available")
                return false
            }
        } else {
            // Error 401 means "No records match the request"
            if let errorData = try? JSONDecoder().decode(FileMakerFindResponse.self, from: data),
               let firstMessage = errorData.messages.first,
               firstMessage.code == "401" {
                print("   ✅ Email is available (no matching records)")
                return false
            }
            throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Creates a new user record
    private func performCreateUser(firstName: String, lastName: String, email: String, password: String, token: String) async throws -> Bool {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/records"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.emailFieldName: email,
            FileMakerConfig.passwordFieldName: password,
            "first_name": firstName,
            "last_name": lastName
        ]
        
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        print("📝 Creating user record in FileMaker...")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        print("   Create Response Status: \(httpResponse.statusCode)")
        logResponse(data: data)
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let createResponse = try JSONDecoder().decode(FileMakerCreateResponse.self, from: data)
            
            if let firstMessage = createResponse.messages.first {
                print("   📊 First message code: [\(firstMessage.code)]")
                print("   📊 First message text: \(firstMessage.message)")
                
                if firstMessage.code == "0" {
                    print("✅ User record created successfully (Code: 0)")
                    return true
                } else {
                    print("❌ Create error: [\(firstMessage.code)] \(firstMessage.message)")
                    throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
                }
            } else {
                print("✅ User record created successfully (No messages, HTTP 201)")
                return true
            }
        } else {
            try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
            throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Updates the user's Currency field in FileMaker (test_table_login)
    private func performUpdateUserCurrency(userID: String, currency: String, token: String) async throws {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/records/\(userID)"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.userCurrencyField: currency
        ]
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "PATCH", body: body, sessionToken: token)
        
        print("📝 Updating user currency in FileMaker: \(currency)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Currency updated successfully")
            return
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    /// Updates the user's Theme field in FileMaker (test_table_login)
    private func performUpdateUserTheme(userID: String, theme: String, token: String) async throws {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/records/\(userID)"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.userThemeField: theme
        ]
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "PATCH", body: body, sessionToken: token)
        
        print("📝 Updating user theme in FileMaker: \(theme)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Theme updated successfully")
            return
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    /// Updates the user's expense limit in FileMaker (test_table_login)
    private func performUpdateUserExpenseLimit(userID: String, type: String, value: Double, period: String, token: String) async throws {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/records/\(userID)"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.userExpenseLimitTypeField: type,
            FileMakerConfig.userExpenseLimitValueField: value,
            FileMakerConfig.userExpenseLimitPeriodField: period
        ]
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "PATCH", body: body, sessionToken: token)
        
        print("📝 Updating user expense limit in FileMaker: \(type)=\(value) \(period)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Expense limit updated successfully")
            return
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    /// Updates the user's password in FileMaker (test_table_login.account_password)
    private func performUpdateUserPassword(userID: String, newPassword: String, token: String) async throws {
        let endpoint = "layouts/\(FileMakerConfig.layoutName)/records/\(userID)"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.passwordFieldName: newPassword
        ]
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "PATCH", body: body, sessionToken: token)
        
        print("📝 Updating user password in FileMaker")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Password updated successfully")
            return
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    /// Creates an expense record in FileMaker
    private func performCreateExpense(userID: String, date: Date, amount: Double, categoryID: String, paymentMethod: String, description: String, type: ExpenseType, token: String) async throws -> String {
        let endpoint = "layouts/\(FileMakerConfig.expenseLayoutName)/records"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        // FileMaker often expects MM/dd/yyyy for Date field validation
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        let fieldData: [String: Any] = [
            FileMakerConfig.expenseUserIDField: userID,
            FileMakerConfig.expenseDateField: dateString,
            FileMakerConfig.expenseAmountField: amount,
            FileMakerConfig.expenseCategoryIDField: categoryID,
            FileMakerConfig.expensePaymentMethodField: paymentMethod,
            FileMakerConfig.expenseDescriptionField: description,
            FileMakerConfig.expenseTypeField: type.rawValue
        ]
        
        let body = try requestBuilder.createRecordBody(fieldData: fieldData)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        print("📝 Creating expense record in FileMaker...")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let createResponse = try JSONDecoder().decode(FileMakerCreateResponse.self, from: data)
            if let recordId = createResponse.response?.recordId {
                print("✅ Expense record created: \(recordId)")
                return recordId
            }
            if let firstMessage = createResponse.messages.first, firstMessage.code != "0" {
                throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
            }
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.invalidResponse
    }
    
    /// Fetches expenses for a user from FileMaker
    private func performFetchExpenses(userID: String, token: String) async throws -> [Expense] {
        let endpoint = "layouts/\(FileMakerConfig.expenseLayoutName)/_find"
        let url = try requestBuilder.buildURL(endpoint: endpoint)
        
        let queryFields: [String: Any] = [
            FileMakerConfig.expenseUserIDField: "==\(userID)"
        ]
        let body = try requestBuilder.createFindQueryWithFields(fields: queryFields, limit: 500)
        let request = requestBuilder.createRequest(url: url, method: "POST", body: body, sessionToken: token)
        
        print("📥 Fetching expenses for UserID: \(userID)")
        let (data, response) = try await performRequest(request: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileMakerError.invalidResponse
        }
        
        print("   Expense response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            let expenseResponse: FileMakerExpenseFindResponse
            do {
                expenseResponse = try JSONDecoder().decode(FileMakerExpenseFindResponse.self, from: data)
            } catch {
                let preview = String(data: data, encoding: .utf8).map { String($0.prefix(600)) } ?? "nil"
                print("❌ Expense decode failed: \(error)")
                print("   Response preview: \(preview)")
                throw error
            }
            
            guard let records = expenseResponse.response?.data else {
                print("⚠️ No expense data in response (response.data is nil or empty)")
                if let info = expenseResponse.response?.dataInfo {
                    print("   dataInfo: foundCount=\(info.foundCount ?? -1), returnedCount=\(info.returnedCount ?? -1)")
                }
                return []
            }
            
            print("   Found \(records.count) expense record(s)")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateFormatterAlt = DateFormatter()
            dateFormatterAlt.dateFormat = "MM/dd/yyyy"
            let timestampFormatters: [DateFormatter] = {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let f1 = DateFormatter()
                f1.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let f2 = DateFormatter()
                f2.dateFormat = "MM/dd/yyyy HH:mm:ss"
                let f3 = DateFormatter()
                f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return [f1, f2, f3]
            }()
            
            let expenses = records.compactMap { record -> Expense? in
                let amountStr = record.fieldData.Amount
                let amount = amountStr.flatMap { Double($0) } ?? 0
                let typeStr = record.fieldData.transactionType?.trimmingCharacters(in: .whitespaces).lowercased()
                let type: ExpenseType = (typeStr == "income") ? .income : ((typeStr == "expense") ? .expense : .expense)
                
                var date = Date()
                if let dateStr = record.fieldData.Date, !dateStr.isEmpty {
                    date = dateFormatter.date(from: dateStr)
                        ?? dateFormatterAlt.date(from: dateStr)
                        ?? date
                }
                
                var creationTimestamp: Date? = nil
                if let tsStr = record.fieldData.CreationTimestamp, !tsStr.isEmpty {
                    creationTimestamp = ISO8601DateFormatter().date(from: tsStr)
                    if creationTimestamp == nil {
                        for f in timestampFormatters {
                            if let parsed = f.date(from: tsStr) {
                                creationTimestamp = parsed
                                break
                            }
                        }
                    }
                }
                
                return Expense(
                    id: record.recordId,
                    title: record.fieldData.Description ?? "",
                    amount: amount,
                    categoryID: record.fieldData.CategoryID ?? "",
                    date: date,
                    type: type,
                    paymentMethod: record.fieldData.PaymentMethod,
                    notes: nil,
                    creationTimestamp: creationTimestamp
                )
            }
            
            print("✅ Loaded \(expenses.count) expense(s)")
            return expenses
        }
        
        if httpResponse.statusCode == 401, let errorData = try? JSONDecoder().decode(FileMakerExpenseFindResponse.self, from: data),
           errorData.messages?.first?.code == "401" {
            print("   No expenses match (401)")
            return []
        }
        try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
        throw FileMakerError.httpError(statusCode: httpResponse.statusCode)
    }
    
    // MARK: - Helper Methods
    
    /// Performs a network request
    private func performRequest(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            print("❌ URL Error in performRequest:")
            print("   Code: \(urlError.code.rawValue) - \(urlError.code)")
            print("   Description: \(urlError.localizedDescription)")
            print("   URL: \(request.url?.absoluteString ?? "unknown")")
            throw FileMakerError.networkError("\(urlError.localizedDescription) (Code: \(urlError.code.rawValue))")
        } catch {
            print("❌ Network error in performRequest: \(error.localizedDescription)")
            throw FileMakerError.networkError(error.localizedDescription)
        }
    }
    
    /// Handles error responses from FileMaker API
    private func handleErrorResponse(data: Data, statusCode: Int) throws {
        print("❌ Request failed with status: \(statusCode)")
        
        // Try to parse FileMaker error message (try both response types)
        if let errorData = try? JSONDecoder().decode(FileMakerFindResponse.self, from: data),
           let firstMessage = errorData.messages.first {
            print("   FileMaker Error: [\(firstMessage.code)] \(firstMessage.message)")
            
            if firstMessage.code == "812" {
                throw FileMakerError.capacityExceeded
            } else if firstMessage.code == "401" || statusCode == 401 {
                throw FileMakerError.authenticationFailed
            }
            throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
        } else if let errorData = try? JSONDecoder().decode(FileMakerCreateResponse.self, from: data),
                  let firstMessage = errorData.messages.first {
            print("   FileMaker Error: [\(firstMessage.code)] \(firstMessage.message)")
            
            if firstMessage.code == "812" {
                throw FileMakerError.capacityExceeded
            } else if firstMessage.code == "401" || statusCode == 401 {
                throw FileMakerError.authenticationFailed
            }
            throw FileMakerError.apiError(code: firstMessage.code, message: firstMessage.message)
        }
        
        if statusCode == 401 {
            print("   HTTP 401 - Authentication failed")
            throw FileMakerError.authenticationFailed
        }
    }
    
    /// Logs response data for debugging
    private func logResponse(data: Data) {
        if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
            let preview = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
            print("   Response Body: \(preview)")
        }
    }
}
