import CloudKit
import Foundation

enum CloudKitConfiguration {
    static let containerIdentifierInfoKey = "NUDGE_CLOUDKIT_CONTAINER_IDENTIFIER"

    static func configuredContainerIdentifier(
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String? {
        if let envValue = environment[containerIdentifierInfoKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !envValue.isEmpty {
            return envValue
        }

        if let infoValue = (infoDictionary?[containerIdentifierInfoKey] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !infoValue.isEmpty {
            return infoValue
        }

        return nil
    }

    static func makeContainer(
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> CKContainer? {
        guard let identifier = configuredContainerIdentifier(infoDictionary: infoDictionary, environment: environment) else {
            return nil
        }
        return CKContainer(identifier: identifier)
    }
}
