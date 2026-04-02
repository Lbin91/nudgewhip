import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
final class LaunchAtLoginManager: LaunchAtLoginManaging {
    private let service: SMAppService
    
    init(service: SMAppService = .mainApp) {
        self.service = service
    }
    
    var isEnabled: Bool {
        service.status == .enabled
    }
    
    func setEnabled(_ enabled: Bool) throws {
        switch (enabled, service.status) {
        case (true, .enabled):
            return
        case (true, _):
            try service.register()
        case (false, .notRegistered), (false, .notFound):
            return
        case (false, _):
            try service.unregister()
        }
    }
}
