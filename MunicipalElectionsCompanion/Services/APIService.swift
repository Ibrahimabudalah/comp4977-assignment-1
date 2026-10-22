//
//  APIService.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "You are not authorized."
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Could not read server data."
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

final class APIService {
    static let shared = APIService()

    // replace this when you finish the dotnet API
    private let baseURL = "https://blabla.blabla.com"

    private init() {}

    func get<T: Decodable>(
        _ endpoint: String,
        token: String? = nil
    ) async throws -> T {
        try await request(
            endpoint,
            method: "GET",
            token: token
        )
    }

    func post<T: Decodable, B: Encodable>(
        _ endpoint: String,
        body: B,
        token: String? = nil
    ) async throws -> T {
        try await request(
            endpoint,
            method: "POST",
            body: body,
            token: token
        )
    }

    func delete(
        _ endpoint: String,
        token: String? = nil
    ) async throws {
        let _: EmptyResponse = try await request(
            endpoint,
            method: "DELETE",
            token: token
        )
    }

    private func request<T: Decodable>(
        _ endpoint: String,
        method: String,
        token: String? = nil
    ) async throws -> T {
        try await send(
            endpoint,
            method: method,
            token: token,
            body: nil
        )
    }

    private func request<T: Decodable, B: Encodable>(
        _ endpoint: String,
        method: String,
        body: B,
        token: String? = nil
    ) async throws -> T {
        let data = try JSONEncoder().encode(body)

        return try await send(
            endpoint,
            method: method,
            token: token,
            body: data
        )
    }

    private func send<T: Decodable>(
        _ endpoint: String,
        method: String,
        token: String?,
        body: Data?
    ) async throws -> T {
        guard let url = URL(
            string: baseURL + endpoint
        ) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if let body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        if let token = token ?? TokenManager.shared.getToken() {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(
                for: request
            )
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(
                httpResponse.statusCode
            )
        }

        if data.isEmpty, T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try JSONDecoder().decode(
                T.self,
                from: data
            )
        } catch {
            throw APIError.decodingError
        }
    }
}

struct EmptyResponse: Decodable {}
