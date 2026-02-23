import Foundation

/// Parses wrapper shell scripts to extract job configuration
enum ScriptParser {
    struct ScriptData {
        var prompt: String?
        var workingDirectory: String?
        var allowedTools: [String]?
        var mcpConfig: String?
    }

    /// Parse a wrapper script to extract prompt, CWD, tools, and MCP config
    static func parse(at path: String) -> ScriptData? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var result = ScriptData()

        // Extract working directory from "cd /path/to/dir"
        if let cdMatch = content.range(of: #"cd\s+(/\S+)"#, options: .regularExpression) {
            let line = String(content[cdMatch])
            let path = line.replacingOccurrences(of: "cd ", with: "").trimmingCharacters(in: .whitespaces)
            result.workingDirectory = path
        }

        // Extract prompt from `claude -p "..."` or `claude -p '...'`
        result.prompt = extractPrompt(from: content)

        // Extract allowed tools from --allowedTools "tool1,tool2"
        if let toolsMatch = content.range(of: #"--allowedTools\s+"([^"]+)""#, options: .regularExpression) {
            let match = String(content[toolsMatch])
            if let quoteStart = match.firstIndex(of: "\""),
               let quoteEnd = match.lastIndex(of: "\""), quoteStart < quoteEnd {
                let tools = String(match[match.index(after: quoteStart)..<quoteEnd])
                result.allowedTools = tools.split(separator: ",").map(String.init)
            }
        }

        // Extract MCP config path from --mcp-config /path
        if let mcpMatch = content.range(of: #"--mcp-config\s+(\S+)"#, options: .regularExpression) {
            let match = String(content[mcpMatch])
            let path = match.replacingOccurrences(of: "--mcp-config ", with: "").trimmingCharacters(in: .whitespaces)
            result.mcpConfig = path
        }

        return result
    }

    private static func extractPrompt(from content: String) -> String? {
        // Match claude -p "multi-line prompt possibly with escaped quotes"
        // The prompt can span multiple lines and end with a quote followed by optional backslash or flags
        let patterns = [
            #"claude\s+-p\s+"((?:[^"\\]|\\.)*)""#,  // double-quoted
            #"claude\s+-p\s+'((?:[^'\\]|\\.)*)'"#,   // single-quoted
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
                if let range = Range(match.range(at: 1), in: content) {
                    return String(content[range])
                }
            }
        }

        return nil
    }
}
