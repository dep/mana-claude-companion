import ServiceManagement

class LoginItemManager {
    static let shared = LoginItemManager()

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func enable() {
        try? SMAppService.mainApp.register()
    }

    func disable() {
        try? SMAppService.mainApp.unregister()
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }
}
