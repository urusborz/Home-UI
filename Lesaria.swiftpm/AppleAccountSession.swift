import Foundation
import AuthenticationServices

struct AppleAccountSession: Codable {
    var userID: String
    var email: String?
    var fullName: String?
    var signedInAt: Date

    var displayTitle: String {
        if let fullName, !fullName.isEmpty { return fullName }
        if let email, !email.isEmpty { return email }
        return "Apple Account"
    }

    init(credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        email = credential.email
        if let name = credential.fullName {
            fullName = PersonNameComponentsFormatter().string(from: name)
        } else {
            fullName = nil
        }
        signedInAt = Date()
    }
}

