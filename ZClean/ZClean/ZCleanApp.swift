import SwiftUI
import SwiftData

@main
struct ZCleanApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DashboardView()
            }
            .environment(\.locale, Locale(identifier: "en_GB"))
        }
        .modelContainer(for: [Contact.self, Job.self])
    }
}
