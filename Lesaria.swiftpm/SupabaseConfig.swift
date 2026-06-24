import Foundation

enum SupabaseConfig {
    // Client-side Supabase values are public by design. Never put a service-role
    // or secret key here. Fill these from Project Settings > API.
    static let projectURL = "https://pchphabfibfnulqprhrd.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjaHBoYWJmaWJmbnVscXByaHJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMDQ4NTcsImV4cCI6MjA5Nzg4MDg1N30.ggRngDviJbz38G3P4EBMSBowVeHBXtebrD4hdZQz2E0"

    static var isConfigured: Bool {
        !projectURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
