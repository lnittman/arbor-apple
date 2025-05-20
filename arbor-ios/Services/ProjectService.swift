import Foundation

class ProjectService {
    private let apiManager = APIManager.shared
    
    /// Create a new project
    func createProject(name: String, description: String? = nil, imageData: Data? = nil) async throws -> Project {
        var body: [String: Any] = ["name": name]
        
        if let description = description {
            body["description"] = description
        }
        
        // Note: imageData handling might need a separate endpoint or multipart/form-data
        // approach if the API supports image uploads in the future
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        return try await apiManager.request(endpoint: "/api/projects", method: "POST", body: bodyData, decodingType: Project.self)
    }
    
    /// Get a project by ID
    func getProject(id: String) async throws -> Project {
        return try await apiManager.request(endpoint: "/api/projects/\(id)", decodingType: Project.self)
    }
    
    /// Get all projects
    func getAllProjects() async throws -> [Project] {
        let projects = try await apiManager.request(endpoint: "/api/projects", decodingType: [Project].self)
        return projects.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    /// Update a project
    func updateProject(_ project: Project) async throws -> Project {
        var body: [String: Any] = ["name": project.name]
        
        if let description = project.projectDescription {
            body["description"] = description
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        return try await apiManager.request(endpoint: "/api/projects/\(project.id)", method: "PUT", body: bodyData, decodingType: Project.self)
    }
    
    /// Delete a project
    func deleteProject(id: String) async throws {
        try await apiManager.requestVoid(endpoint: "/api/projects/\(id)", method: "DELETE")
    }
} 