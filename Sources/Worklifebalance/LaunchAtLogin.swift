import ServiceManagement
import SwiftUI

class LaunchAtLogin: ObservableObject {
    static let shared = LaunchAtLogin()

    var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("cannot change launch at login: \(error)")
            }
        }
    }
}
