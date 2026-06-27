# Lesaria TestFlight + CloudKit Setup

Diese Repo ist fuer TestFlight vorbereitet. Die letzten Schritte passieren im Apple Developer Portal und in App Store Connect.

## App IDs und Capabilities

1. Oeffne Apple Developer > Certificates, Identifiers & Profiles > Identifiers.
2. Lege die App ID `com.urusborz.lesaria` an oder oeffne sie.
3. Aktiviere `Sign in with Apple`.
4. Aktiviere `iCloud` und darin `CloudKit`.
5. Lege den iCloud Container `iCloud.com.urusborz.lesaria` an und weise ihn der App ID zu.
6. Speichere die App ID.
7. Oeffne das Projekt auf dem iPad in Swift Playgrounds > App Settings > Capabilities und aktiviere ebenfalls `Sign in with Apple` sowie `iCloud/CloudKit`, falls diese dort angeboten werden. Die Repo enthaelt `Lesaria.swiftpm/Lesaria.entitlements` als Referenz fuer die erwarteten Entitlements.

## App Store Connect

1. Lege in App Store Connect eine neue iOS-App `Lesaria` mit Bundle ID `com.urusborz.lesaria` an.
2. Verbinde die GitHub-Repo `urusborz/Lesaria` mit Xcode Cloud.
3. Waehle als Projektordner `Lesaria.swiftpm`.
4. Waehle Scheme `Lesaria`.
5. Nutze `main` als Branch.
6. Setze die Distribution auf TestFlight.

## GitHub Actions Upload von Windows aus

Da Xcode Cloud den ersten Workflow in Xcode erwartet, nutzt diese Repo fuer Windows den Workflow `.github/workflows/testflight.yml`.

Lege in GitHub > Settings > Secrets and variables > Actions diese Repository Secrets an:

- `APPLE_TEAM_ID`: Team ID aus dem Apple Developer Account
- `APP_STORE_CONNECT_KEY_ID`: Key ID des App Store Connect API Keys
- `APP_STORE_CONNECT_ISSUER_ID`: Issuer ID aus App Store Connect API
- `APP_STORE_CONNECT_API_KEY_BASE64`: Inhalt der heruntergeladenen `.p8` API-Key-Datei als Base64

Der Workflow setzt `bundleVersion` ueber `ci_scripts/ci_pre_xcodebuild.sh` auf die aktuelle GitHub-Run-Nummer, baut auf `macos-15`, signiert automatisch und laedt die IPA zu TestFlight hoch.

## CloudKit Schema

Die App speichert einen privaten Datensatz pro iCloud Account:

- Container: `iCloud.com.urusborz.lesaria`
- Database: Private Database
- Record Type: `LesariaSnapshot`
- Record ID: `primary`
- Fields: `payloadData` (Bytes), `updatedAt` (Date/Time), `schemaVersion` (Number), `deviceID` (String)

Beim ersten erfolgreichen TestFlight-Start erzeugt die App den Datensatz automatisch.
