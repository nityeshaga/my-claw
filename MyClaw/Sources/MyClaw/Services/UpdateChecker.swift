import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    static let currentVersion = "1.0.0"
    private let repo = "nityeshaga/my-claw"

    @Published var latestVersion: String?
    @Published var downloadURL: String?
    @Published var releaseNotes: String?
    @Published var updateAvailable = false
    @Published var checking = false

    private var lastCheck: Date?
    private let checkInterval: TimeInterval = 60 * 60 * 4 // 4 hours

    func checkIfNeeded() {
        if let last = lastCheck, Date().timeIntervalSince(last) < checkInterval {
            return
        }
        check()
    }

    func check() {
        guard !checking else { return }
        checking = true

        Task {
            defer { checking = false }

            guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return }

            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    return
                }

                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    return
                }

                let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                self.latestVersion = version
                self.releaseNotes = json["body"] as? String

                // Find the .zip asset download URL
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String,
                           name.hasSuffix(".zip"),
                           let url = asset["browser_download_url"] as? String {
                            self.downloadURL = url
                            break
                        }
                    }
                }

                // Fall back to the release page if no zip asset
                if self.downloadURL == nil, let htmlURL = json["html_url"] as? String {
                    self.downloadURL = htmlURL
                }

                self.lastCheck = Date()
                self.updateAvailable = isNewer(version, than: Self.currentVersion)
            } catch {
                // Silently fail — update check is best-effort
            }
        }
    }

    /// Simple semver comparison: returns true if `a` is newer than `b`
    private func isNewer(_ a: String, than b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(aParts.count, bParts.count) {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av > bv { return true }
            if av < bv { return false }
        }
        return false
    }
}
