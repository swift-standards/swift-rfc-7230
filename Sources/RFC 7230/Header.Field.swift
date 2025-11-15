import Foundation

extension RFC_7230.Header {
    /// An HTTP header field (name-value pair) per RFC 7230 Section 3.2.
    ///
    /// Represents a complete header field in HTTP/1.1 messages.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let value = try RFC_7230.Header.Field.Value("application/json")
    /// let name = RFC_7230.Header.Field.Name("Content-Type")
    /// let field = RFC_7230.Header.Field(name: name, value: value)
    /// ```
    ///
    /// ## RFC 7230 Structure
    ///
    /// ```
    /// header-field   = field-name ":" OWS field-value OWS
    /// field-name     = token
    /// field-value    = *( field-content / obs-fold )
    /// field-content  = field-vchar [ 1*( SP / HTAB ) field-vchar ]
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 7230 Section 3.2: Header Fields](https://tools.ietf.org/html/rfc7230#section-3.2)
    public struct Field: Hashable, Sendable {
        /// The header field name
        public let name: Name

        /// The header field value
        public let value: Value

        /// Creates an HTTP header field.
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The validated header field value
        public init(name: Name, value: Value) {
            self.name = name
            self.value = value
        }
    }
}

// MARK: - Field.Name

extension RFC_7230.Header.Field {
    /// An HTTP header field name per RFC 7230 Section 3.2.
    ///
    /// Header field names are case-insensitive tokens.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let contentType = RFC_7230.Header.Field.Name("Content-Type")
    /// let customHeader = RFC_7230.Header.Field.Name("X-Custom-Header")
    /// ```
    ///
    /// ## Reference
    ///
    /// From RFC 7230 Section 3.2:
    ///
    /// ```
    /// field-name     = token
    /// token          = 1*tchar
    /// tchar          = "!" / "#" / "$" / "%" / "&" / "'" / "*"
    ///                / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
    ///                / DIGIT / ALPHA
    /// ```
    public struct Name: Hashable, Sendable {
        /// The header field name
        public let rawValue: String

        /// Creates a header field name.
        ///
        /// - Parameter rawValue: The header field name
        ///
        /// - Note: Header field names are case-insensitive per RFC 7230,
        ///   but we preserve the original case for display purposes.
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// Hash value (case-insensitive)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue.lowercased())
        }

        /// Equality comparison (case-insensitive)
        public static func == (lhs: Name, rhs: Name) -> Bool {
            lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
        }
    }
}

// MARK: - Field.Value

extension RFC_7230.Header.Field {
    /// A validated HTTP header field value per RFC 7230 Section 3.2.
    ///
    /// This type ensures header field values conform to RFC 7230 requirements,
    /// specifically that they do not contain CR (carriage return) or LF (line feed)
    /// characters, which would allow header injection attacks.
    ///
    /// ## RFC 7230 Requirements
    ///
    /// From RFC 7230 Section 3.2:
    ///
    /// ```
    /// field-content  = field-vchar [ 1*( SP / HTAB ) field-vchar ]
    /// field-vchar    = VCHAR / obs-text
    /// ```
    ///
    /// Notably, CR and LF are not allowed in field-content.
    ///
    /// ## Security
    ///
    /// This validation prevents HTTP header injection attacks where an attacker
    /// could inject additional headers or control characters by including CRLF
    /// sequences in header values.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Valid header value
    /// let contentType = try RFC_7230.Header.Field.Value("application/json")
    ///
    /// // Invalid - contains CRLF
    /// do {
    ///     let malicious = try RFC_7230.Header.Field.Value("value\r\nX-Evil: injected")
    /// } catch {
    ///     print("Rejected: \(error)")
    /// }
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 7230 Section 3.2: Header Fields](https://tools.ietf.org/html/rfc7230#section-3.2)
    public struct Value: Hashable, Sendable {
        /// The validated header field value
        public let rawValue: String

        /// Creates a validated header field value.
        ///
        /// - Parameter rawValue: The header field value to validate
        /// - Throws: `ValidationError` if the value contains CR or LF characters
        ///
        /// ## Example
        ///
        /// ```swift
        /// let valid = try RFC_7230.Header.Field.Value("text/html; charset=utf-8")
        /// ```
        public init(_ rawValue: String) throws {
            // RFC 7230 Section 3.2: field-content cannot contain CR or LF
            // Check for CR (U+000D) and LF (U+000A) characters
            if rawValue.unicodeScalars.contains(where: { $0 == "\r" }) {
                throw ValidationError.invalidFieldValue(
                    value: rawValue,
                    reason: "Header field value contains CR (carriage return) character, forbidden by RFC 7230 §3.2"
                )
            }

            if rawValue.unicodeScalars.contains(where: { $0 == "\n" }) {
                throw ValidationError.invalidFieldValue(
                    value: rawValue,
                    reason: "Header field value contains LF (line feed) character, forbidden by RFC 7230 §3.2"
                )
            }

            self.rawValue = rawValue
        }

        /// Creates a field value without validation.
        ///
        /// - Parameter rawValue: The header field value
        ///
        /// - Warning: This initializer bypasses validation and should only be used
        ///   when you have already validated the input or are certain it's safe.
        public init(unchecked rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Validation Error

extension RFC_7230.Header.Field {
    /// Errors that occur during header field validation
    public enum ValidationError: Error, Sendable {
        /// The header field value is invalid
        case invalidFieldValue(value: String, reason: String)
    }
}

// MARK: - LocalizedError Conformance

extension RFC_7230.Header.Field.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFieldValue(let value, let reason):
            return "Invalid HTTP header field value: \(reason) - Value: \"\(value)\""
        }
    }
}

// MARK: - Name String Conversion

extension RFC_7230.Header.Field.Name: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension RFC_7230.Header.Field.Name: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Value String Conversion

extension RFC_7230.Header.Field.Value: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Field String Conversion

extension RFC_7230.Header.Field: CustomStringConvertible {
    /// Returns the header field in RFC 7230 format (name: value)
    public var description: String {
        "\(name.rawValue): \(value.rawValue)"
    }
}
