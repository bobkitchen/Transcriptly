import Foundation
// Temporarily disabled - Supabase package needs to be added via Swift Package Manager
// import Supabase

final class SupabaseConfig: Sendable {
    static let shared = SupabaseConfig()
    
    // TODO: Replace with your actual Supabase project credentials
    // Get these from https://app.supabase.com -> Project Settings -> API
    private let supabaseURL = "https://zmrpwxbixwhxgjaifyza.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcnB3eGJpeHdoeGdqYWlmeXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMTk1MjEsImV4cCI6MjA2NjU5NTUyMX0.Wxnz2FMF5pC_rvOLg3CIs6QQ0hKgdwAgd2C0f9oCdQs"
    
    // Temporarily commented out until Supabase package is added
    // let client: SupabaseClient
    
    private init() {
        // Temporarily disabled
        /*
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
        */
    }
    
    // Validate configuration
    var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_SUPABASE") && !supabaseAnonKey.contains("YOUR_SUPABASE")
    }
}