import Foundation

// Copy this file as MatrixTestConfig.swift in the Xcode project.
// Values belong to one test Supabase project. Never place service_role or private keys here.
enum MatrixTestConfig {
    static let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    static let supabasePublishableKey = "YOUR-ANON-OR-PUBLISHABLE-KEY"
}
