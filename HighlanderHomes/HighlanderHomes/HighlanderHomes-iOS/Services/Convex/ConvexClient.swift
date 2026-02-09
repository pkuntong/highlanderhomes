import Foundation
import Combine

/// Convex client for iOS - handles queries, mutations, and real-time subscriptions
/// Uses Convex HTTP API with WebSocket for live updates
@MainActor
class ConvexClient: ObservableObject {
    static let shared = ConvexClient()

    // MARK: - Published State
    @Published var isConnected: Bool = false
    @Published var connectionError: String?

    // MARK: - Private Properties
    private let baseURL: URL
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var subscriptions: [String: (Any) -> Void] = [:]
    private var authToken: String?

    private init() {
        guard let url = URL(string: ConvexConfig.deploymentURL) else {
            fatalError("Invalid Convex deployment URL")
        }
        self.baseURL = url

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
        reconnectWebSocket()
    }

    func clearAuth() {
        self.authToken = nil
        webSocketTask?.cancel()
        isConnected = false
    }

    // MARK: - Query (Read Data)
    func query<T: Decodable>(
        _ functionName: String,
        args: [String: Any] = [:]
    ) async throws -> T {
        let endpoint = baseURL.appendingPathComponent("api/query")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        applyAuthHeaderIfNeeded(&request)

        let body: [String: Any] = [
            "path": functionName,
            "args": args,
            "format": "json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data),
               let message = errorBody.message, !message.isEmpty {
                throw ConvexError.serverError(message)
            }
            if let message = extractErrorMessage(from: data) {
                throw ConvexError.serverError(message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decodeResponse(data)
    }

    // MARK: - Mutation (Write Data)
    func mutation<T: Decodable>(
        _ functionName: String,
        args: [String: Any] = [:]
    ) async throws -> T {
        let endpoint = baseURL.appendingPathComponent("api/mutation")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        applyAuthHeaderIfNeeded(&request)

        let body: [String: Any] = [
            "path": functionName,
            "args": args,
            "format": "json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data),
               let message = errorBody.message, !message.isEmpty {
                throw ConvexError.serverError(message)
            }
            if let message = extractErrorMessage(from: data) {
                throw ConvexError.serverError(message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decodeResponse(data)
    }

    // Mutation that returns void
    func mutation(
        _ functionName: String,
        args: [String: Any] = [:]
    ) async throws {
        let _: EmptyConvexResponse = try await mutation(functionName, args: args)
    }

    // MARK: - Action (Server-side logic)
    func action<T: Decodable>(
        _ functionName: String,
        args: [String: Any] = [:]
    ) async throws -> T {
        let endpoint = baseURL.appendingPathComponent("api/action")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        applyAuthHeaderIfNeeded(&request)

        let body: [String: Any] = [
            "path": functionName,
            "args": args,
            "format": "json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data),
               let message = errorBody.message, !message.isEmpty {
                throw ConvexError.serverError(message)
            }
            if let message = extractErrorMessage(from: data) {
                throw ConvexError.serverError(message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decodeResponse(data)
    }

    // MARK: - WebSocket for Real-time Updates
    func connect() {
        guard webSocketTask == nil else { return }

        var wsURLString = ConvexConfig.deploymentURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        wsURLString += "/api/\(ConvexConfig.apiVersion)/sync"

        guard let wsURL = URL(string: wsURLString) else {
            connectionError = "Invalid WebSocket URL"
            return
        }

        var request = URLRequest(url: wsURL)
        applyAuthHeaderIfNeeded(&request)

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true

        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        subscriptions.removeAll()
    }

    private func reconnectWebSocket() {
        disconnect()
        connect()
        // Re-subscribe to all active subscriptions
        for (queryName, _) in subscriptions {
            subscribeToQuery(queryName)
        }
    }

    private func applyAuthHeaderIfNeeded(_ request: inout URLRequest) {
        guard let token = authToken, isJWT(token) else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func isJWT(_ token: String) -> Bool {
        token.split(separator: ".").count == 3
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                Task { @MainActor in
                    self?.connectionError = error.localizedDescription
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryPath = json["queryPath"] as? String,
                  let value = json["value"] else {
                return
            }

            Task { @MainActor in
                subscriptions[queryPath]?(value)
            }

        case .data(let data):
            // Handle binary data if needed
            print("Received binary data: \(data.count) bytes")

        @unknown default:
            break
        }
    }

    // MARK: - Subscriptions
    func subscribe<T: Decodable>(
        to queryName: String,
        args: [String: Any] = [:],
        onUpdate: @escaping (T) -> Void
    ) {
        subscriptions[queryName] = { value in
            if let data = try? JSONSerialization.data(withJSONObject: value),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                onUpdate(decoded)
            }
        }

        subscribeToQuery(queryName, args: args)
    }

    private func subscribeToQuery(_ queryName: String, args: [String: Any] = [:]) {
        guard let webSocketTask = webSocketTask else {
            connect()
            return
        }

        let message: [String: Any] = [
            "type": "subscribe",
            "queryPath": queryName,
            "args": args
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocketTask.send(.string(string)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        }
    }

    func unsubscribe(from queryName: String) {
        subscriptions.removeValue(forKey: queryName)

        guard let webSocketTask = webSocketTask else { return }

        let message: [String: Any] = [
            "type": "unsubscribe",
            "queryPath": queryName
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocketTask.send(.string(string)) { _ in }
        }
    }
}

// MARK: - Response Types
struct ConvexResponse<T: Decodable>: Decodable {
    let value: T?
    let status: String?
    let error: ConvexErrorResponse?
}

struct ConvexErrorResponse: Decodable {
    let code: String?
    let message: String?
}

struct EmptyConvexResponse: Decodable {}

// MARK: - Errors
enum ConvexError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case serverError(String)
    case notAuthenticated
    case encodingError
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return message
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Decoding
private extension ConvexClient {
    func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        do {
            let wrapper = try decoder.decode(ConvexResponse<T>.self, from: data)

            if let status = wrapper.status, status.lowercased() == "error" {
                if let message = wrapper.error?.message, !message.isEmpty {
                    throw ConvexError.serverError(message)
                }
                if let message = extractErrorMessage(from: data) {
                    throw ConvexError.serverError(message)
                }
                throw ConvexError.serverError("Unknown server error")
            }

            if let value = wrapper.value {
                return value
            }

            if T.self == EmptyConvexResponse.self {
                return EmptyConvexResponse() as! T
            }

            throw ConvexError.invalidResponse
        } catch let error as ConvexError {
            throw error
        } catch {
            throw ConvexError.decodingError(error)
        }
    }

    func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let message = json["message"] as? String, !message.isEmpty {
            return message
        }

        if let errorString = json["error"] as? String, !errorString.isEmpty {
            return errorString
        }

        if let errorDict = json["error"] as? [String: Any] {
            if let message = errorDict["message"] as? String, !message.isEmpty {
                return message
            }
            if let dataMessage = errorDict["data"] as? String, !dataMessage.isEmpty {
                return dataMessage
            }
        }

        return nil
    }
}
