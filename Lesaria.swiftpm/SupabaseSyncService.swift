import Foundation

struct SupabaseSyncConfiguration {
    var projectURL: String
    var anonKey: String
    var syncID: String
    var syncToken: String

    var isConfigured: Bool {
        !projectURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !syncID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !syncToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SupabaseSnapshot: Codable {
    var id: String
    var payload: BackupPayload
    var updatedAt: Date?
    var deviceID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case payload
        case updatedAt = "updated_at"
        case deviceID = "device_id"
    }
}

private struct SupabaseSnapshotWrite: Encodable {
    var id: String
    var payload: BackupPayload
    var deviceID: String
    var syncToken: String

    enum CodingKeys: String, CodingKey {
        case id
        case payload
        case deviceID = "device_id"
        case syncToken = "sync_token"
    }
}

enum SupabaseSyncError: LocalizedError {
    case missingConfiguration
    case invalidProjectURL
    case requestFailed(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase ist noch nicht konfiguriert."
        case .invalidProjectURL:
            return "Die Supabase-Projekt-URL ist ungueltig."
        case let .requestFailed(status, message):
            return "Supabase-Request fehlgeschlagen (\(status)): \(message)"
        case .emptyResponse:
            return "In Supabase wurde noch kein Sync-Stand gefunden."
        }
    }
}

final class SupabaseSyncService {
    private let configuration: SupabaseSyncConfiguration
    private let session: URLSession

    init(configuration: SupabaseSyncConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func fetchSnapshot() async throws -> SupabaseSnapshot {
        try ensureConfigured()
        var components = try restComponents(path: "lesaria_snapshots")
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(configuration.syncID)"),
            URLQueryItem(name: "select", value: "id,payload,updated_at,device_id"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components.url else { throw SupabaseSyncError.invalidProjectURL }

        var request = URLRequest(url: url)
        addHeaders(to: &request)

        let data = try await perform(request)
        let rows = try decoder().decode([SupabaseSnapshot].self, from: data)
        guard let snapshot = rows.first else { throw SupabaseSyncError.emptyResponse }
        return snapshot
    }

    @discardableResult
    func upsertSnapshot(_ payload: BackupPayload) async throws -> SupabaseSnapshot {
        try ensureConfigured()
        var components = try restComponents(path: "lesaria_snapshots")
        components.queryItems = [
            URLQueryItem(name: "on_conflict", value: "id")
        ]
        guard let url = components.url else { throw SupabaseSyncError.invalidProjectURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder().encode(
            SupabaseSnapshotWrite(
                id: configuration.syncID,
                payload: payload,
                deviceID: Self.deviceID,
                syncToken: configuration.syncToken
            )
        )

        let data = try await perform(request)
        let rows = try decoder().decode([SupabaseSnapshot].self, from: data)
        guard let snapshot = rows.first else { throw SupabaseSyncError.emptyResponse }
        return snapshot
    }

    private func ensureConfigured() throws {
        guard configuration.isConfigured else { throw SupabaseSyncError.missingConfiguration }
    }

    private func restComponents(path: String) throws -> URLComponents {
        guard let baseURL = URL(string: configuration.projectURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = baseURL.host else {
            throw SupabaseSyncError.invalidProjectURL
        }

        var components = URLComponents()
        components.scheme = baseURL.scheme ?? "https"
        components.host = host
        components.path = "/rest/v1/\(path)"
        return components
    }

    private func addHeaders(to request: inout URLRequest) {
        let anonKey = configuration.anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.syncToken.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "x-lesaria-sync-token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return data }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw SupabaseSyncError.requestFailed(http.statusCode, message)
        }
        return data
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = Self.iso8601Formatter.date(from: value) {
                return date
            }
            if let date = Self.iso8601FormatterWithFractionalSeconds.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }
        return decoder
    }

    private static var deviceID: String {
        let key = "supabaseDeviceID"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    private static let iso8601FormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
