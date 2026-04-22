import Foundation

enum CURLBuilder {
    /// Renders a NetworkRecord as a copy-pasteable cURL command.
    /// Escapes single quotes and skips the body when not UTF-8 representable.
    static func build(_ record: NetworkRecord) -> String {
        var lines: [String] = []
        lines.append("curl -X \(record.method.uppercased()) \\")
        for (key, value) in record.requestHeaders.sorted(by: { $0.key < $1.key }) {
            lines.append("  -H \(quote("\(key): \(value)")) \\")
        }
        if let body = record.requestBody, let bodyString = String(data: body, encoding: .utf8) {
            lines.append("  --data-raw \(quote(bodyString)) \\")
        }
        lines.append("  \(quote(record.url.absoluteString))")
        return lines.joined(separator: "\n")
    }

    private static func quote(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
