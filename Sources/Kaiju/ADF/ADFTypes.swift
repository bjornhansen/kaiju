import Foundation

/// Atlassian Document Format document root
struct ADFDocument: Codable, Sendable, Equatable {
    let version: Int
    let type: String
    let content: [ADFNode]

    init(version: Int = 1, type: String = "doc", content: [ADFNode]) {
        self.version = version
        self.type = type
        self.content = content
    }

    /// Create a simple ADF document wrapping plain text
    static func plainText(_ text: String) -> ADFDocument {
        ADFDocument(content: [
            ADFNode(type: "paragraph", content: [
                ADFNode(type: "text", text: text)
            ])
        ])
    }
}

/// A node in the ADF tree
struct ADFNode: Codable, Sendable, Equatable {
    let type: String
    let text: String?
    let content: [ADFNode]?
    let marks: [ADFMark]?
    let attrs: ADFAttributes?

    init(
        type: String,
        text: String? = nil,
        content: [ADFNode]? = nil,
        marks: [ADFMark]? = nil,
        attrs: ADFAttributes? = nil
    ) {
        self.type = type
        self.text = text
        self.content = content
        self.marks = marks
        self.attrs = attrs
    }
}

/// Text marks (bold, italic, code, link, etc.)
struct ADFMark: Codable, Sendable, Equatable {
    let type: String
    let attrs: ADFMarkAttributes?

    init(type: String, attrs: ADFMarkAttributes? = nil) {
        self.type = type
        self.attrs = attrs
    }
}

struct ADFMarkAttributes: Codable, Sendable, Equatable {
    let href: String?
    let title: String?
    let language: String?

    init(href: String? = nil, title: String? = nil, language: String? = nil) {
        self.href = href
        self.title = title
        self.language = language
    }
}

/// Node-level attributes (heading level, code language, etc.)
struct ADFAttributes: Codable, Sendable, Equatable {
    let level: Int?
    let language: String?
    let order: Int?
    let url: String?

    init(level: Int? = nil, language: String? = nil, order: Int? = nil, url: String? = nil) {
        self.level = level
        self.language = language
        self.order = order
        self.url = url
    }
}
