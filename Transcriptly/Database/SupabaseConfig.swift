import Foundation

struct SupabaseConfig {
    // TODO: Replace with actual Supabase project credentials
    // Get these from https://app.supabase.com -> Project Settings -> API
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_SUPABASE_ANON_KEY"
    
    // Validate configuration
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_SUPABASE") && !supabaseAnonKey.contains("YOUR_SUPABASE")
    }
}