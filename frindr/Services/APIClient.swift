//
//  APIClient.swift
//  frindr
//
//  HTTP client with bearer token authentication
//

import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://api.frindr.app")!
    private let bearerToken = "your-api-token-here"  // TODO: Configure with actual token

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let session: URLSession

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499:
            throw APIError.clientError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Request without response body

    func requestNoContent(
        endpoint: Endpoint,
        method: HTTPMethod,
        body: (any Encodable)? = nil
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499:
            throw APIError.clientError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Image Upload (Multipart)

    func uploadImage(data: Data, filename: String = "image.jpg") async throws -> ImageUploadResponse {
        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/images/upload"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var bodyData = Data()

        // Add image data
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = bodyData

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.clientError(statusCode: httpResponse.statusCode, message: String(data: responseData, encoding: .utf8))
        }

        return try decoder.decode(ImageUploadResponse.self, from: responseData)
    }

    // MARK: - Connectivity Check

    func isReachable() async -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("health"))
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

enum Endpoint {
    case meals
    case meal(UUID)
    case mealEaten(UUID)
    case familyMembers
    case familyMember(UUID)
    case favorites(familyMemberId: UUID, mealId: UUID)
    case imageUpload
    case imageDelete(String)

    var path: String {
        switch self {
        case .meals:
            return "api/v1/meals"
        case .meal(let id):
            return "api/v1/meals/\(id.uuidString)"
        case .mealEaten(let id):
            return "api/v1/meals/\(id.uuidString)/eaten"
        case .familyMembers:
            return "api/v1/family-members"
        case .familyMember(let id):
            return "api/v1/family-members/\(id.uuidString)"
        case .favorites(let memberId, let mealId):
            return "api/v1/family-members/\(memberId.uuidString)/favorites/\(mealId.uuidString)"
        case .imageUpload:
            return "api/v1/images/upload"
        case .imageDelete(let key):
            return "api/v1/images/\(key)"
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case clientError(statusCode: Int, message: String?)
    case serverError(statusCode: Int)
    case unknown(statusCode: Int)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication failed"
        case .notFound:
            return "Resource not found"
        case .clientError(let code, let message):
            return message ?? "Client error (\(code))"
        case .serverError(let code):
            return "Server error (\(code))"
        case .unknown(let code):
            return "Unknown error (\(code))"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }

    var isNetworkError: Bool {
        if case .networkUnavailable = self { return true }
        return false
    }
}

struct ImageUploadResponse: Codable {
    let url: String
    let key: String
}

// Type-erasing wrapper for Encodable
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self.encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
