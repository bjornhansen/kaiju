import Foundation

/// Parses ADF JSON data into typed ADFDocument
enum ADFParser {
    /// Parse raw JSON data into an ADFDocument
    static func parse(data: Data) throws -> ADFDocument {
        let decoder = JSONDecoder()
        return try decoder.decode(ADFDocument.self, from: data)
    }

    /// Parse a JSON string into an ADFDocument
    static func parse(jsonString: String) throws -> ADFDocument {
        guard let data = jsonString.data(using: .utf8) else {
            throw ADFParserError.invalidInput
        }
        return try parse(data: data)
    }

    /// Convert an ADFDocument to JSON data for API submission
    static func encode(_ document: ADFDocument) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(document)
    }

    /// Convert an ADFDocument to a JSON string
    static func encodeToString(_ document: ADFDocument) throws -> String {
        let data = try encode(document)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ADFParserError.encodingFailed
        }
        return string
    }

    /// Extract plain text from an ADF document (strips formatting)
    static func extractPlainText(from document: ADFDocument) -> String {
        return document.content.map { extractText(from: $0) }.joined()
    }

    private static func extractText(from node: ADFNode) -> String {
        var result = ""

        if let text = node.text {
            result += text
        }

        if let children = node.content {
            result += children.map { extractText(from: $0) }.joined()
        }

        // Add newlines after block-level elements
        switch node.type {
        case "paragraph", "heading", "codeBlock", "blockquote":
            result += "\n"
        case "hardBreak":
            result += "\n"
        case "listItem":
            result += "\n"
        default:
            break
        }

        return result
    }
}

enum ADFParserError: Error, Sendable {
    case invalidInput
    case encodingFailed
}
