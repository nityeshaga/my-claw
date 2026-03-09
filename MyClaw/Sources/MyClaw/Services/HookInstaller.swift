import Foundation

/// Single source of truth for the app version (not actor-isolated)
enum AppVersion {
    static let current = "1.2.0"
}

/// Installs and manages the Claude Code SessionEnd hook that populates the session index
enum HookInstaller {
    enum InstallResult {
        case installed
        case updated
        case alreadyUpToDate
        case failed(String)
    }

    private static let home = FileManager.default.homeDirectoryForCurrentUser.path
    private static var settingsPath: String { "\(home)/.claude/settings.json" }
    private static var scriptPath: String { "\(home)/.claude/job-monitor/my-claw-session-hook.sh" }
    private static var jobMonitorDir: String { "\(home)/.claude/job-monitor" }
    private static let hookCommand = "$HOME/.claude/job-monitor/my-claw-session-hook.sh"

    /// Check and install/update the SessionEnd hook. Safe to call every launch.
    static func installIfNeeded() -> InstallResult {
        let fm = FileManager.default

        // 1. Ensure job-monitor directory exists
        do {
            try fm.createDirectory(atPath: jobMonitorDir, withIntermediateDirectories: true)
        } catch {
            return .failed("Cannot create job-monitor directory: \(error.localizedDescription)")
        }

        // 2. Write/update hook script
        let scriptUpdated = installScript()

        // 3. Update settings.json
        let settingsResult = installSettingsHook()

        switch settingsResult {
        case .failed:
            return settingsResult
        case .installed:
            return .installed
        case .updated:
            return .updated
        case .alreadyUpToDate:
            return scriptUpdated ? .updated : .alreadyUpToDate
        }
    }

    /// Remove the hook from settings.json and delete the script.
    static func uninstall() {
        let fm = FileManager.default

        // Remove script file
        try? fm.removeItem(atPath: scriptPath)

        // Remove from settings.json
        guard let data = fm.contents(atPath: settingsPath),
              var settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        guard var hooks = settings["hooks"] as? [String: Any],
              var handlers = hooks["SessionEnd"] as? [[String: Any]] else {
            return
        }

        handlers.removeAll { matcherGroup in
            guard let innerHooks = matcherGroup["hooks"] as? [[String: Any]] else { return false }
            return innerHooks.contains { ($0["command"] as? String)?.contains("my-claw-session-hook.sh") ?? false }
        }

        if handlers.isEmpty {
            hooks.removeValue(forKey: "SessionEnd")
        } else {
            hooks["SessionEnd"] = handlers
        }

        if hooks.isEmpty {
            settings.removeValue(forKey: "hooks")
        } else {
            settings["hooks"] = hooks
        }

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            fm.createFile(atPath: settingsPath, contents: jsonData)
        }
    }

    /// Check whether the hook is currently installed (script + settings entry).
    static func isInstalled() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: scriptPath) else { return false }
        guard let data = fm.contents(atPath: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = settings["hooks"] as? [String: Any],
              let handlers = hooks["SessionEnd"] as? [[String: Any]] else {
            return false
        }
        return handlers.contains { matcherGroup in
            guard let innerHooks = matcherGroup["hooks"] as? [[String: Any]] else { return false }
            return innerHooks.contains { ($0["command"] as? String)?.contains("my-claw-session-hook.sh") ?? false }
        }
    }

    // MARK: - Private

    private static func installScript() -> Bool {
        let fm = FileManager.default
        let currentVersion = AppVersion.current

        // Check existing version
        if let existing = fm.contents(atPath: scriptPath),
           let content = String(data: existing, encoding: .utf8) {
            if let range = content.range(of: #"MYCLAW_HOOK_VERSION=(\S+)"#, options: .regularExpression) {
                let versionLine = String(content[range])
                let version = versionLine.replacingOccurrences(of: "MYCLAW_HOOK_VERSION=", with: "")
                if version == currentVersion {
                    return false // Already up to date
                }
            }
        }

        // Write new script
        let script = generateScript(version: currentVersion)
        guard fm.createFile(atPath: scriptPath, contents: script.data(using: .utf8)) else {
            return false
        }
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
        return true
    }

    private static func installSettingsHook() -> InstallResult {
        let fm = FileManager.default

        // Read existing settings or start fresh
        var settings: [String: Any]
        if let data = fm.contents(atPath: settingsPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = json
        } else if fm.fileExists(atPath: settingsPath) {
            return .failed("settings.json exists but is not valid JSON")
        } else {
            settings = [:]
        }

        // Navigate to hooks.SessionEnd
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        var sessionEndHandlers = hooks["SessionEnd"] as? [[String: Any]] ?? []

        // Check if our hook is already present (search in nested matcher group structure)
        let existingIndex = sessionEndHandlers.firstIndex { matcherGroup in
            guard let innerHooks = matcherGroup["hooks"] as? [[String: Any]] else { return false }
            return innerHooks.contains { ($0["command"] as? String)?.contains("my-claw-session-hook.sh") ?? false }
        }

        if let idx = existingIndex {
            // Verify command is correct
            if let innerHooks = sessionEndHandlers[idx]["hooks"] as? [[String: Any]],
               let cmd = innerHooks.first?["command"] as? String,
               cmd == hookCommand {
                return .alreadyUpToDate
            }
            // Update the command
            sessionEndHandlers[idx] = buildMatcherGroup()
        } else {
            // Add new matcher group
            sessionEndHandlers.append(buildMatcherGroup())
        }

        // Write back
        hooks["SessionEnd"] = sessionEndHandlers
        settings["hooks"] = hooks

        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return .failed("Failed to serialize settings.json")
        }

        // Ensure ~/.claude/ directory exists
        try? fm.createDirectory(atPath: "\(home)/.claude", withIntermediateDirectories: true)

        guard fm.createFile(atPath: settingsPath, contents: jsonData) else {
            return .failed("Failed to write settings.json")
        }

        return existingIndex != nil ? .updated : .installed
    }

    private static func buildMatcherGroup() -> [String: Any] {
        [
            "matcher": "",
            "hooks": [
                [
                    "type": "command",
                    "command": hookCommand
                ] as [String: Any]
            ]
        ]
    }

    private static func generateScript(version: String) -> String {
        """
        #!/bin/bash
        # MyClaw SessionEnd Hook v\(version)
        # Installed by MyClaw app -- do not edit manually
        # MYCLAW_HOOK_VERSION=\(version)

        python3 -u << 'PYTHON_SCRIPT'
        import json, sys, os
        from datetime import datetime, timezone

        def main():
            try:
                hook_input = json.loads(sys.stdin.read())
            except Exception:
                sys.exit(0)

            session_id = hook_input.get("session_id", "")
            transcript_path = hook_input.get("transcript_path", "")
            cwd = hook_input.get("cwd", "")
            reason = hook_input.get("reason", "unknown")

            if not session_id or not transcript_path:
                sys.exit(0)

            total_input = 0
            total_output = 0
            num_turns = 0
            first_timestamp = None

            try:
                with open(transcript_path, "r") as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            entry = json.loads(line)
                        except json.JSONDecodeError:
                            continue

                        ts = entry.get("timestamp", "")
                        if ts and first_timestamp is None:
                            first_timestamp = ts

                        entry_type = entry.get("type", "")
                        message = entry.get("message", {})
                        if not isinstance(message, dict):
                            continue

                        if entry_type == "user" and message.get("role") == "user":
                            content = message.get("content")
                            if isinstance(content, str) and content.strip():
                                num_turns += 1

                        if entry_type == "assistant":
                            usage = message.get("usage", {})
                            if usage and isinstance(usage, dict):
                                total_input += usage.get("input_tokens", 0)
                                total_input += usage.get("cache_creation_input_tokens", 0)
                                total_input += usage.get("cache_read_input_tokens", 0)
                                total_output += usage.get("output_tokens", 0)
            except (FileNotFoundError, PermissionError):
                pass

            finished_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            result = {
                "session_id": session_id,
                "transcript_path": transcript_path,
                "cwd": cwd,
                "reason": reason,
                "finished_at": finished_at,
            }
            if num_turns > 0:
                result["num_turns"] = num_turns
            if first_timestamp:
                result["started_at"] = first_timestamp
            if total_input > 0:
                result["total_input_tokens"] = total_input
            if total_output > 0:
                result["total_output_tokens"] = total_output

            index_path = os.path.expanduser("~/.claude/job-monitor/jobs-index.jsonl")
            os.makedirs(os.path.dirname(index_path), exist_ok=True)

            with open(index_path, "a") as f:
                f.write(json.dumps(result, separators=(",", ":")) + "\\n")
                f.flush()

        if __name__ == "__main__":
            main()
        PYTHON_SCRIPT
        """
    }
}
