import Foundation
import Network

final class LocalHTTPServer: @unchecked Sendable {
    private let port: NWEndpoint.Port = 17321
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "ai-progress-hud.http")
    private let lock = NSLock()
    private var commands: [[String: Int]] = []
    private let pairingToken: String
    var onEvent: (@Sendable (BrowserEvent) -> Void)?
    var onStatus: (@Sendable (Bool) -> Void)?
    var onBrowserHeartbeat: (@Sendable () -> Void)?

    init(pairingToken: String) { self.pairingToken = pairingToken }

    func start() {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            let listener = try NWListener(using: parameters, on: port)
            listener.newConnectionHandler = { [weak self] in self?.handle($0) }
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready: self?.onStatus?(true)
                case .failed, .cancelled: self?.onStatus?(false)
                default: break
                }
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch { onStatus?(false) }
    }

    func stop() { listener?.cancel(); listener = nil }

    func enqueueActivate(tabId: Int, windowId: Int?) {
        lock.lock()
        var command = ["tabId": tabId]
        if let windowId { command["windowId"] = windowId }
        commands.append(command)
        lock.unlock()
    }

    private func handle(_ connection: NWConnection) {
        guard case let .hostPort(host, _) = connection.endpoint,
              ["127.0.0.1", "::1"].contains(String(describing: host)) else {
            connection.cancel()
            return
        }
        connection.start(queue: queue)
        receive(on: connection, data: Data())
    }

    private func receive(on connection: NWConnection, data: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1_048_576) { [weak self] chunk, _, complete, error in
            guard let self else { return }
            var accumulated = data
            if let chunk { accumulated.append(chunk) }
            if let request = HTTPRequest.parse(accumulated) {
                self.route(request, connection: connection)
            } else if !complete && error == nil {
                self.receive(on: connection, data: accumulated)
            } else {
                self.respond(connection, status: "400 Bad Request", body: "{}")
            }
        }
    }

    private func route(_ request: HTTPRequest, connection: NWConnection) {
        if request.method == "OPTIONS" {
            respond(connection, status: "204 No Content", body: "")
            return
        }
        if request.method == "POST", request.path == "/event",
           let event = try? Self.decoder.decode(BrowserEvent.self, from: request.body),
           event.token == pairingToken {
            onEvent?(event)
            respond(connection, body: "{\"ok\":true}")
            return
        }
        if request.method == "GET", request.path.hasPrefix("/commands"),
           request.queryValue("token") == pairingToken {
            onBrowserHeartbeat?()
            lock.lock()
            let pending = commands
            commands.removeAll()
            lock.unlock()
            let data = (try? JSONSerialization.data(withJSONObject: pending)) ?? Data("[]".utf8)
            respond(connection, body: String(decoding: data, as: UTF8.self))
            return
        }
        if request.method == "GET", request.path == "/health" {
            respond(connection, body: "{\"ok\":true}")
            return
        }
        if request.method == "GET", request.path.hasPrefix("/pair"),
           request.queryValue("token") == pairingToken {
            onBrowserHeartbeat?()
            respond(connection, body: "{\"ok\":true,\"paired\":true}")
            return
        }
        respond(connection, status: "404 Not Found", body: "{}")
    }

    private func respond(_ connection: NWConnection, status: String = "200 OK", body: String) {
        let response = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Content-Type\r\nConnection: close\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
    }

    private static let decoder: JSONDecoder = {
        let value = JSONDecoder()
        value.dateDecodingStrategy = .millisecondsSince1970
        return value
    }()
}

private struct HTTPRequest {
    var method: String
    var path: String
    var body: Data

    static func parse(_ data: Data) -> HTTPRequest? {
        guard let separator = data.range(of: Data("\r\n\r\n".utf8)),
              let headerText = String(data: data[..<separator.lowerBound], encoding: .utf8) else { return nil }
        let lines = headerText.components(separatedBy: "\r\n")
        let first = lines.first?.split(separator: " ") ?? []
        guard first.count >= 2 else { return nil }
        let lengthLine = lines.first { $0.lowercased().hasPrefix("content-length:") }
        let length = Int(lengthLine?.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? "0") ?? 0
        let bodyStart = separator.upperBound
        guard data.distance(from: bodyStart, to: data.endIndex) >= length else { return nil }
        return HTTPRequest(method: String(first[0]), path: String(first[1]), body: data.subdata(in: bodyStart..<(bodyStart + length)))
    }

    func queryValue(_ name: String) -> String? {
        guard let components = URLComponents(string: "http://localhost\(path)") else { return nil }
        return components.queryItems?.first { $0.name == name }?.value
    }
}
