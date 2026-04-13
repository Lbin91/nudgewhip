import Foundation

@MainActor
final class DeviceIdentityProvider {
    private let userDefaults: UserDefaults
    private let key: String

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "nudgewhip.device_identity"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func macDeviceID() -> String {
        if let existing = userDefaults.string(forKey: key), !existing.isEmpty {
            return existing
        }

        let created = "mac-\(UUID().uuidString.lowercased())"
        userDefaults.set(created, forKey: key)
        return created
    }
}
