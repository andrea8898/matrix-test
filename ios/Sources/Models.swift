import Foundation

struct SessionPayload: Codable {
    let profileId: UUID
    let publicCode: String
    let displayName: String?
    let isFounder: Bool?
    let sessionToken: String
}

struct MatrixProfile: Codable, Identifiable {
    let id: UUID
    let publicCode: String
    let username: String
    let displayName: String
    let status: String
}

struct AdminSummary: Codable {
    let registeredAccounts: Int
    let onlineAccounts: Int
    let disabledAccounts: Int
}

struct AdminAccount: Codable, Identifiable {
    let id: UUID
    let sequenceNo: Int64
    let username: String
    let displayName: String
    let status: String
    let disabledAt: Date?

    var publicCode: String { "E\(sequenceNo)" }
}

struct DashboardOutput: Codable {
    let summary: AdminSummary
    let accounts: [AdminAccount]
}

enum MatrixAPIError: LocalizedError {
    case configuration, server(String), decoding
    var errorDescription: String? {
        switch self {
        case .configuration: return "Configura URL e chiave publishable di Supabase."
        case .server(let message): return message
        case .decoding: return "Risposta del server non valida."
        }
    }
}
