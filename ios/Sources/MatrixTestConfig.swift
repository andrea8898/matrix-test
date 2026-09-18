import Foundation

// Replace these two values on the Mac after creating the dedicated Supabase test project.
// The publishable/anon key may be used by the app. Never put service_role here.
enum MatrixTestConfig {
    static let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    static let supabasePublishableKey = "YOUR-ANON-OR-PUBLISHABLE-KEY"

    static var isConfigured: Bool {
        !supabaseURL.host!.contains("YOUR-PROJECT") && !supabasePublishableKey.contains("YOUR-")
    }
}
