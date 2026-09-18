import SwiftUI

@main
struct MatrixTestApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            MatrixRootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
