import CloudKit
import Foundation

enum CloudKitConfig {
    static let containerIdentifier = "iCloud.com.urusborz.lesaria"
    static let recordType = "LesariaSnapshot"
    static let recordName = "primary"
}

struct CloudKitSnapshot {
    var payload: BackupPayload
    var updatedAt: Date?
    var deviceID: String?
}

enum CloudKitSyncError: LocalizedError {
    case accountUnavailable
    case emptyResponse
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            return "Bitte melde dich auf diesem Gerät bei iCloud an."
        case .emptyResponse:
            return "Es wurde noch kein iCloud-Sync-Stand gefunden."
        case .invalidPayload:
            return "Der iCloud-Sync-Stand konnte nicht gelesen werden."
        }
    }
}

final class CloudKitSyncService {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordID = CKRecord.ID(recordName: CloudKitConfig.recordName)

    init(containerIdentifier: String = CloudKitConfig.containerIdentifier) {
        container = CKContainer(identifier: containerIdentifier)
        database = container.privateCloudDatabase
    }

    func ensureAvailable() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            throw CloudKitSyncError.accountUnavailable
        }
    }

    func fetchSnapshot() async throws -> CloudKitSnapshot {
        try await ensureAvailable()
        let record = try await database.record(for: recordID)
        return try snapshot(from: record)
    }

    @discardableResult
    func upsertSnapshot(_ payload: BackupPayload) async throws -> CloudKitSnapshot {
        try await ensureAvailable()
        let record = await existingRecordOrNew()
        let encoded = try encoder().encode(payload)
        let now = Date()

        record["payloadData"] = encoded as CKRecordValue
        record["updatedAt"] = now as CKRecordValue
        record["schemaVersion"] = NSNumber(value: payload.version)
        record["deviceID"] = Self.deviceID as CKRecordValue

        let saved = try await database.save(record)
        return try snapshot(from: saved)
    }

    private func existingRecordOrNew() async -> CKRecord {
        do {
            return try await database.record(for: recordID)
        } catch {
            return CKRecord(recordType: CloudKitConfig.recordType, recordID: recordID)
        }
    }

    private func snapshot(from record: CKRecord) throws -> CloudKitSnapshot {
        guard let payloadData = record["payloadData"] as? Data else {
            throw CloudKitSyncError.invalidPayload
        }
        let payload = try decoder().decode(BackupPayload.self, from: payloadData)
        return CloudKitSnapshot(
            payload: payload,
            updatedAt: record["updatedAt"] as? Date ?? record.modificationDate,
            deviceID: record["deviceID"] as? String
        )
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static var deviceID: String {
        let key = "cloudKitDeviceID"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
