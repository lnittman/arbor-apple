import Foundation
import Clerk

enum APIError: Error {
    case networkError(Error)
    case invalidResponse(URLResponse?)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case unknown
}

class APIManager {
    static let shared = APIManager()
    private var baseURL: URL
    private var isAuthenticated: Bool = false
    
    private init() {
        // Load baseURL from Info.plist
        #if DEBUG
        // if let urlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseURL") as? String,
        if let url = URL(string: "https://99c56b3fdfea.ngrok.app") {
            self.baseURL = url
        } else {
            fatalError("API Base URL not configured in Info.plist")
        }
        #else
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseURLProduction") as? String,
           let url = URL(string: urlString) {
            self.baseURL = url
        } else {
            fatalError("Production API Base URL not configured in Info.plist")
        }
        #endif
        print("🚀 APIManager initialized with base URL: \(self.baseURL)")
        
        // Check authentication status initially
        Task {
            await checkAuthentication()
        }
    }
    
    /// Extract just the JWT string from the TokenResource
    private func extractJWTToken(from tokenResource: Any) -> String? {
        // Convert tokenResource to a string
        let tokenString = String(describing: tokenResource)
        
        // Look for the JWT pattern in the string - it's between quotes after "jwt: "
        if let range = tokenString.range(of: "jwt: \"(.+?)\"", options: .regularExpression) {
            // Extract the JWT part (remove the 'jwt: "' prefix and the trailing '"')
            let jwtWithQuotes = tokenString[range]
            let jwt = jwtWithQuotes.dropFirst(6).dropLast(1) // Drop 'jwt: "' and the trailing '"'
            return String(jwt)
        }
        
        return nil
    }
    
    /// Check if the user is authenticated with Clerk and update the isAuthenticated flag
    func checkAuthentication() async -> Bool {
        do {
            if let tokenResource = try await Clerk.shared.session?.getToken() {
                if let jwt = extractJWTToken(from: tokenResource) {
                    isAuthenticated = true
                    return true
                } else {
                    print("❌ Failed to extract JWT from token resource")
                    isAuthenticated = false
                    return false
                }
            } else {
                print("❌ No Clerk session token available")
                isAuthenticated = false
                return false
            }
        } catch {
            print("🚨 Error checking Clerk authentication: \(error)")
            isAuthenticated = false
            return false
        }
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        decodingType: T.Type
    ) async throws -> T {
        // First check authentication status
        let isAuth = await checkAuthentication()
        
        // If not authenticated and this is a collection type (like array), return empty collection
        // instead of throwing an error during initial load
        if !isAuth {
            if decodingType is [Any].Type {
                // Create an empty array of the expected type
                let emptyArray = [] as! T
                return emptyArray
            }
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add host and origin headers required by Clerk
        request.setValue(url.host, forHTTPHeaderField: "Host")
        request.setValue(baseURL.absoluteString, forHTTPHeaderField: "Origin")
        request.setValue(baseURL.absoluteString, forHTTPHeaderField: "Referer")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("Mozilla/5.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        // Add Clerk Auth Token
        do {
            if let tokenResource = try await Clerk.shared.session?.getToken() {
                if let jwt = extractJWTToken(from: tokenResource) {
                    request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                } else {
                    print("⚠️ Failed to extract JWT from token resource")
                    throw APIError.unauthorized
                }
            } else {
                print("⚠️ No Clerk token found, request will be unauthorized.")
                throw APIError.unauthorized
            }
        } catch {
            print("🚨 Error fetching Clerk token: \(error)")
            throw APIError.unauthorized
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        print("➡️ \(method) \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(response)
        }
        
        print("⬅️ \(httpResponse.statusCode) \(url.absoluteString)")
        
        // Print response headers for debugging
        if httpResponse.statusCode == 401 {
            print("🔍 AUTH ERROR - Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("\(key): \(value)")
            }
            
            // Try to parse the error response
            if let errorText = String(data: data, encoding: .utf8) {
                print("🔍 Error response body: \(errorText)")
            }
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                
                // Configure date decoding to handle different formats
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try ISO8601 first (which is what we're expecting)
                    if let date = ISO8601DateFormatter().date(from: dateString) {
                        return date
                    }
                    
                    // Try with our formatter
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try with just the date formatter
                    let justDateFormatter = DateFormatter()
                    justDateFormatter.dateFormat = "yyyy-MM-dd"
                    justDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    if let date = justDateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Print debugging info
                    print("❌ Failed to parse date: \(dateString)")
                    
                    // If all else fails, throw an error
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
                }
                
                let decodedObject = try decoder.decode(T.self, from: data)
                return decodedObject
            } catch {
                print("❌ Decoding Error: \(error)")
                
                // Print the raw response for debugging
                if let responseText = String(data: data, encoding: .utf8) {
                    print("📄 Response JSON: \(responseText)")
                }
                
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            let errorMessage = String(data: data, encoding: .utf8)
            print("❌ Server Error \(httpResponse.statusCode): \(errorMessage ?? "No body")")
            
            // Print the raw response for debugging
            if let responseText = String(data: data, encoding: .utf8) {
                print("📄 Response JSON: \(responseText)")
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        }
    }
    
    func requestVoid(
        endpoint: String,
        method: String = "DELETE",
        body: Data? = nil
    ) async throws {
        // Check authentication status first
        let isAuth = await checkAuthentication()
        if !isAuth {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add host and origin headers required by Clerk
        request.setValue(url.host, forHTTPHeaderField: "Host")
        request.setValue(baseURL.absoluteString, forHTTPHeaderField: "Origin")
        request.setValue(baseURL.absoluteString, forHTTPHeaderField: "Referer")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("Mozilla/5.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        // Add Clerk Auth Token
        do {
            if let tokenResource = try await Clerk.shared.session?.getToken() {
                if let jwt = extractJWTToken(from: tokenResource) {
                    print("🔒 Adding JWT Auth Token to request for \(url.path)")
                    request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                } else {
                    print("⚠️ Failed to extract JWT from token resource")
                    throw APIError.unauthorized
                }
            } else {
                print("⚠️ No Clerk token found, request will be unauthorized.")
                throw APIError.unauthorized
            }
        } catch {
            print("🚨 Error fetching Clerk token: \(error)")
            throw APIError.unauthorized
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        print("➡️ \(method) \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(response)
        }
        
        print("⬅️ \(httpResponse.statusCode) \(url.absoluteString)")
        
        // Print response headers for debugging
        if httpResponse.statusCode == 401 {
            print("🔍 AUTH ERROR - Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("\(key): \(value)")
            }
            
            // Try to parse the error response
            if let errorText = String(data: data, encoding: .utf8) {
                print("🔍 Error response body: \(errorText)")
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            print("❌ Server Error \(httpResponse.statusCode): \(errorMessage ?? "No body")")
            
            // Print the raw response for debugging
            if let responseText = String(data: data, encoding: .utf8) {
                print("📄 Response JSON: \(responseText)")
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        }
    }
} 
