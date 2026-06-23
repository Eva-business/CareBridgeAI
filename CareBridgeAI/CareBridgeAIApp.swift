import SwiftUI
import SwiftData

@main
struct CareBridgeAIApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: PersistedAccountState.self,
                PersistedCareContent.self
            )
            CareAccountStore.shared.configure(with: modelContainer.mainContext)
        } catch {
            fatalError("無法建立本機資料庫：\(error.localizedDescription)")
        }

        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
