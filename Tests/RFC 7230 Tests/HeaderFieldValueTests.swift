import Testing
import Foundation
@testable import RFC_7230

@Suite("RFC_7230.Header.Field.Value Tests")
struct HeaderFieldValueTests {

    @Test("Valid header values are accepted")
    func testValidHeaderValues() throws {
        // Standard content types
        let contentType = try RFC_7230.Header.Field.Value("application/json")
        #expect(contentType.rawValue == "application/json")

        // With parameters
        let withParams = try RFC_7230.Header.Field.Value("text/html; charset=utf-8")
        #expect(withParams.rawValue == "text/html; charset=utf-8")

        // Long values
        let long = try RFC_7230.Header.Field.Value("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        #expect(long.rawValue.hasPrefix("Bearer "))

        // With spaces and tabs
        let withSpaces = try RFC_7230.Header.Field.Value("value with spaces")
        #expect(withSpaces.rawValue == "value with spaces")

        // Empty value (technically valid per RFC)
        let empty = try RFC_7230.Header.Field.Value("")
        #expect(empty.rawValue == "")
    }

    @Test("Header values with CR are rejected")
    func testCarriageReturnRejected() throws {
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("value\rwith\rCR")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("value\r")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("\rvalue")
        }
    }

    @Test("Header values with LF are rejected")
    func testLineFeedRejected() throws {
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("value\nwith\nLF")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("value\n")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("\nvalue")
        }
    }

    @Test("Header values with CRLF are rejected (injection prevention)")
    func testCRLFRejected() throws {
        // This is the classic header injection attack vector
        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("value\r\nX-Evil: injected")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("normal\r\n\r\n<script>alert('xss')</script>")
        }

        #expect(throws: RFC_7230.Header.Field.ValidationError.self) {
            try RFC_7230.Header.Field.Value("\r\n")
        }
    }

    @Test("Unchecked initializer bypasses validation")
    func testUncheckedInitializer() {
        // This should not throw, even with invalid content
        let invalid = RFC_7230.Header.Field.Value(unchecked: "value\r\ninjected")
        #expect(invalid.rawValue == "value\r\ninjected")

        // But you shouldn't use this in production!
    }

    @Test("Field.Value is Hashable and Equatable")
    func testHashableEquatable() throws {
        let value1 = try RFC_7230.Header.Field.Value("application/json")
        let value2 = try RFC_7230.Header.Field.Value("application/json")
        let value3 = try RFC_7230.Header.Field.Value("text/html")

        #expect(value1 == value2)
        #expect(value1 != value3)
        #expect(value1.hashValue == value2.hashValue)
    }

    @Test("Field.Value CustomStringConvertible")
    func testCustomStringConvertible() throws {
        let value = try RFC_7230.Header.Field.Value("test-value")
        #expect(String(describing: value) == "test-value")
    }

    @Test("Error messages are descriptive")
    func testErrorMessages() {
        do {
            _ = try RFC_7230.Header.Field.Value("value\r\ninjected")
            #expect(Bool(false), "Should have thrown")
        } catch let error as RFC_7230.Header.Field.ValidationError {
            let description = error.localizedDescription
            #expect(description.contains("RFC 7230"))
            #expect(description.contains("CR") || description.contains("carriage return"))
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Complete Field with Name and Value")
    func testCompleteField() throws {
        let name = RFC_7230.Header.Field.Name("Content-Type")
        let value = try RFC_7230.Header.Field.Value("application/json")
        let field = RFC_7230.Header.Field(name: name, value: value)

        #expect(field.name.rawValue == "Content-Type")
        #expect(field.value.rawValue == "application/json")
        #expect(String(describing: field) == "Content-Type: application/json")
    }

    @Test("Field.Name is case-insensitive")
    func testFieldNameCaseInsensitive() {
        let name1 = RFC_7230.Header.Field.Name("Content-Type")
        let name2 = RFC_7230.Header.Field.Name("content-type")
        let name3 = RFC_7230.Header.Field.Name("CONTENT-TYPE")

        #expect(name1 == name2)
        #expect(name2 == name3)
        #expect(name1.hashValue == name2.hashValue)
    }

    @Test("Field.Name preserves original case for display")
    func testFieldNamePreservesCase() {
        let name = RFC_7230.Header.Field.Name("Content-Type")
        #expect(name.rawValue == "Content-Type")
        #expect(String(describing: name) == "Content-Type")
    }
}
