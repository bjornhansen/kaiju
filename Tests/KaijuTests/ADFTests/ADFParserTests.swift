import XCTest
@testable import Kaiju

final class ADFParserTests: XCTestCase {

    func test_parse_simple_paragraph() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Hello world"}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        XCTAssertEqual(doc.version, 1)
        XCTAssertEqual(doc.type, "doc")
        XCTAssertEqual(doc.content.count, 1)
        XCTAssertEqual(doc.content[0].type, "paragraph")
        XCTAssertEqual(doc.content[0].content?.count, 1)
        XCTAssertEqual(doc.content[0].content?[0].text, "Hello world")
    }

    func test_parse_heading() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"Title"}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        XCTAssertEqual(doc.content[0].type, "heading")
        XCTAssertEqual(doc.content[0].attrs?.level, 2)
        XCTAssertEqual(doc.content[0].content?[0].text, "Title")
    }

    func test_parse_text_with_marks() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"bold text","marks":[{"type":"strong"}]}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        let textNode = doc.content[0].content![0]
        XCTAssertEqual(textNode.text, "bold text")
        XCTAssertEqual(textNode.marks?.count, 1)
        XCTAssertEqual(textNode.marks?[0].type, "strong")
    }

    func test_parse_bullet_list() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Item 1"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Item 2"}]}]}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        XCTAssertEqual(doc.content[0].type, "bulletList")
        XCTAssertEqual(doc.content[0].content?.count, 2)
    }

    func test_parse_code_block() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"codeBlock","attrs":{"language":"swift"},"content":[{"type":"text","text":"let x = 1"}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        XCTAssertEqual(doc.content[0].type, "codeBlock")
        XCTAssertEqual(doc.content[0].attrs?.language, "swift")
        XCTAssertEqual(doc.content[0].content?[0].text, "let x = 1")
    }

    func test_parse_link_mark() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"click here","marks":[{"type":"link","attrs":{"href":"https://example.com","title":"Example"}}]}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)

        let mark = doc.content[0].content![0].marks![0]
        XCTAssertEqual(mark.type, "link")
        XCTAssertEqual(mark.attrs?.href, "https://example.com")
        XCTAssertEqual(mark.attrs?.title, "Example")
    }

    func test_plain_text_factory() {
        let doc = ADFDocument.plainText("Hello")

        XCTAssertEqual(doc.version, 1)
        XCTAssertEqual(doc.type, "doc")
        XCTAssertEqual(doc.content.count, 1)
        XCTAssertEqual(doc.content[0].type, "paragraph")
        XCTAssertEqual(doc.content[0].content?[0].text, "Hello")
    }

    func test_extract_plain_text() throws {
        let json = """
        {"version":1,"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Hello "},{"type":"text","text":"world","marks":[{"type":"strong"}]}]},{"type":"paragraph","content":[{"type":"text","text":"Second paragraph"}]}]}
        """
        let doc = try ADFParser.parse(jsonString: json)
        let text = ADFParser.extractPlainText(from: doc)

        XCTAssertTrue(text.contains("Hello world"))
        XCTAssertTrue(text.contains("Second paragraph"))
    }

    func test_encode_and_decode_roundtrip() throws {
        let original = ADFDocument.plainText("Test content")
        let encoded = try ADFParser.encode(original)
        let decoded = try ADFParser.parse(data: encoded)

        XCTAssertEqual(original, decoded)
    }

    func test_malformed_json_throws_error() {
        XCTAssertThrowsError(try ADFParser.parse(jsonString: "not json")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_invalid_input_throws_error() {
        XCTAssertThrowsError(try ADFParser.parse(jsonString: "")) { error in
            // Either DecodingError or ADFParserError
            XCTAssertTrue(error is DecodingError || error is ADFParserError)
        }
    }
}
