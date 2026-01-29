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

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data) {
                throw ConvexError.serverError(errorBody.message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        // Convex wraps response in { "value": ... }
        let wrapper = try decoder.decode(ConvexResponse<T>.self, from: data)
        return wrapper.value
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

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data) {
                throw ConvexError.serverError(errorBody.message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        let wrapper = try decoder.decode(ConvexResponse<T>.self, from: data)
        return wrapper.value
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

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
            if let errorBody = try? JSONDecoder().decode(ConvexErrorResponse.self, from: data) {
                throw ConvexError.serverError(errorBody.message)
            }
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        let wrapper = try decoder.decode(ConvexResponse<T>.self, from: data)
        return wrapper.value
    }

    // MARK: - WebSocket for Real-time Updates
    func connect() {
        guard webSocketTask == nil else { return }

        var wsURLString = ConvexConfig.deploymentURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        wsURLString += "/sync"

        guard let wsURL = URL(string: wsURLString) else {
            connectionError = "Invalid WebSocket URL"
            return
        }

        var request = URLRequest(url: wsURL)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
    let value: T
    let status: String?
}

struct ConvexErrorResponse: Decodable {
    let code: String
    let message: String
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
