import Foundation

/// Parses .jsonl files line by line
enum JSONLParser {
    /// Parse a JSONL file into an array of decoded objects
    static func parse<T: Decodable>(_ type: T.Type, from path: String) -> [T] {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }
        return parseString(type, from: content)
    }

    /// Parse JSONL content string into decoded objects
    static func parseString<T: Decodable>(_ type: T.Type, from content: String) -> [T] {
        let decoder = JSONDecoder()
        return content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(type, from: data)
            }
    }

    /// Parse a JSONL file into raw JSON dictionaries
    static func parseRaw(from path: String) -> [[String: Any]] {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }
        return content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                guard let data = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return nil
                }
                return json
            }
    }

    /// Read new lines appended since a given byte offset; returns (entries, newOffset)
    static func parseTail<T: Decodable>(_ type: T.Type, from path: String, offset: UInt64) -> ([T], UInt64) {
        guard let handle = FileHandle(forReadingAtPath: path) else { return ([], offset) }
        defer { try? handle.close() }

        let fileSize = handle.seekToEndOfFile()
        guard fileSize > offset else { return ([], offset) }

        handle.seek(toFileOffset: offset)
        let newData = handle.readDataToEndOfFile()
        guard let content = String(data: newData, encoding: .utf8) else { return ([], fileSize) }

        let entries = parseString(type, from: content)
        return (entries, fileSize)
    }
}
