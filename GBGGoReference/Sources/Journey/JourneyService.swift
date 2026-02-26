// JourneyService.swift
//
// Calls the companion server to create a journey session. The server handles
// authentication with GBG Go and returns a journey URL for the app to load.
//
// This is the iOS side of the flow documented in the Journey URL guide:
//
//   iOS App  ──▸  Your Backend  ──▸  GBG Go Core SDK
//            ◂──                ◂──
//
// In production, "your backend" is your own server. Here we use the companion
// server included in the server/ directory of this repository.

import Foundation

enum JourneyService {

    // MARK: - Response model

    struct StartResponse: Decodable {
        /// The URL to load in BridgeWebView.
        let journeyUrl: URL
        /// The unique journey instance identifier.
        let instanceId: String
        /// A short-lived token for device authentication.
        let connectToken: String
        /// How long the connect token is valid, in seconds.
        let expiresIn: Int
    }

    // MARK: - Error types

    enum ServiceError: LocalizedError {
        case invalidServerURL(String)
        case serverError(statusCode: Int, message: String)
        case networkError(Error)
        case decodingError(Error)
        case missingJourneyURL

        var errorDescription: String? {
            switch self {
            case .invalidServerURL(let url):
                return "Invalid server URL: \(url). Check the URL format."
            case .serverError(let code, let message):
                return "Server returned \(code): \(message)"
            case .networkError(let error):
                return "Cannot reach the server: \(error.localizedDescription). Is it running?"
            case .decodingError(let error):
                return "Unexpected server response: \(error.localizedDescription)"
            case .missingJourneyURL:
                return "Server did not return a journey URL. Check the server logs."
            }
        }
    }

    // MARK: - API call

    /// Creates a new journey session by calling the companion server.
    ///
    /// - Parameters:
    ///   - serverURL: Base URL of the companion server (e.g. "http://localhost:3000").
    ///   - resourceId: Optional journey template ID. If nil, the server uses its default.
    /// - Returns: A `StartResponse` containing the journey URL and metadata.
    static func startJourney(
        serverURL: String,
        resourceId: String?
    ) async throws -> StartResponse {
        // Build the request URL
        guard let baseURL = URL(string: serverURL),
              let endpoint = URL(string: "/api/journey/start", relativeTo: baseURL) else {
            throw ServiceError.invalidServerURL(serverURL)
        }

        // Build the request body
        var body: [String: Any] = [:]
        if let resourceId {
            body["resourceId"] = resourceId
        }

        // Create the request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if !body.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        // Make the call
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ServiceError.networkError(error)
        }

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let message: String
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorBody["message"] as? String ?? errorBody["error"] as? String {
                message = errorMessage
            } else {
                message = String(data: data, encoding: .utf8) ?? "Unknown error"
            }
            throw ServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        // Decode the response
        do {
            let startResponse = try JSONDecoder().decode(StartResponse.self, from: data)
            return startResponse
        } catch {
            throw ServiceError.decodingError(error)
        }
    }
}
