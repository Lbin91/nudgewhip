import Foundation
import Sparkle

@MainActor
protocol AppUpdating: AnyObject {
    var canCheckForUpdates: Bool { get }
    var isConfigured: Bool { get }
    var onCanCheckForUpdatesChanged: (@MainActor (Bool) -> Void)? { get set }

    func checkForUpdates()
}

@MainActor
final class AppUpdater: AppUpdating {
    private let updaterController: SPUStandardUpdaterController?
    private var canCheckObservation: NSKeyValueObservation?

    private(set) var canCheckForUpdates = false {
        didSet {
            onCanCheckForUpdatesChanged?(canCheckForUpdates)
        }
    }

    let isConfigured: Bool
    var onCanCheckForUpdatesChanged: (@MainActor (Bool) -> Void)?

    init(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        let feedURL = Self.nonEmptyString(for: "SUFeedURL", in: infoDictionary)
        let publicKey = Self.nonEmptyString(for: "SUPublicEDKey", in: infoDictionary)
        self.isConfigured = feedURL != nil && publicKey != nil

        guard isConfigured else {
            self.updaterController = nil
            return
        }

        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = updaterController
        self.canCheckForUpdates = updaterController.updater.canCheckForUpdates
        self.canCheckObservation = updaterController.updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] updater, _ in
            let canCheckForUpdates = updater.canCheckForUpdates
            DispatchQueue.main.async {
                self?.canCheckForUpdates = canCheckForUpdates
            }
        }
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    private static func nonEmptyString(for key: String, in infoDictionary: [String: Any]?) -> String? {
        guard let rawValue = infoDictionary?[key] as? String else { return nil }
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
