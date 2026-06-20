import SwiftUI

@main
struct CareBridgeAIApp: App {
    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
