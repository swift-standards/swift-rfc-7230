
// MARK: - HTTP Namespace

extension RFC_7230 {
    /// HTTP protocol namespace
    public enum HTTP {}
}

// MARK: - HTTP Version

extension RFC_7230.HTTP {
    /// HTTP protocol version per RFC 7230 Section 2.6
    ///
    /// HTTP uses a "<major>.<minor>" numbering scheme to indicate versions of the protocol.
    ///
    /// ## Example
    /// ```swift
    /// let http11 = RFC_7230.HTTP.Version.http11
    /// print(http11.string) // "HTTP/1.1"
    ///
    /// // Custom version
    /// let http2 = RFC_7230.HTTP.Version(major: 2, minor: 0)
    /// print(http2.string) // "HTTP/2.0"
    ///
    /// // Parse from string
    /// let parsed = try RFC_7230.HTTP.Version("HTTP/1.1")
    /// ```
    ///
    /// ## RFC 7230 Reference
    /// ```
    /// HTTP-version = HTTP-name "/" DIGIT "." DIGIT
    /// HTTP-name = %x48.54.54.50 ; "HTTP", case-sensitive
    /// ```
    public struct Version: Sendable, Equatable, Hashable {
        /// Major version number
        public let major: UInt

        /// Minor version number
        public let minor: UInt

        /// Creates an HTTP version
        ///
        /// - Parameters:
        ///   - major: The major version number
        ///   - minor: The minor version number
        public init(major: UInt, minor: UInt) {
            self.major = major
            self.minor = minor
        }

        /// Creates an HTTP version from a string (e.g., "HTTP/1.1")
        ///
        /// - Parameter string: The HTTP version string
        /// - Throws: Error if the string doesn't match HTTP version format
        public init(_ string: String) throws {
            // Expected format: "HTTP/major.minor"
            guard string.hasPrefix("HTTP/") else {
                throw ValidationError.invalidFormat(
                    string,
                    reason: "HTTP version must start with 'HTTP/'"
                )
            }

            let versionPart = string.dropFirst(5) // Remove "HTTP/"
            let components = versionPart.split(separator: ".")

            guard components.count == 2 else {
                throw ValidationError.invalidFormat(
                    string,
                    reason: "HTTP version must be in format 'HTTP/major.minor'"
                )
            }

            guard let major = UInt(components[0]), let minor = UInt(components[1]) else {
                throw ValidationError.invalidFormat(
                    string,
                    reason: "Major and minor version numbers must be integers"
                )
            }

            self.init(major: major, minor: minor)
        }

        /// The string representation of the HTTP version
        ///
        /// Returns the version in the format "HTTP/major.minor"
        public var string: String {
            "HTTP/\(major).\(minor)"
        }

        // MARK: - Common HTTP Versions

        /// HTTP/0.9 - The original HTTP protocol
        public static let http09 = Version(major: 0, minor: 9)

        /// HTTP/1.0 per RFC 1945
        public static let http10 = Version(major: 1, minor: 0)

        /// HTTP/1.1 per RFC 7230
        public static let http11 = Version(major: 1, minor: 1)

        /// HTTP/2 per RFC 7540
        public static let http2 = Version(major: 2, minor: 0)

        /// HTTP/3 per RFC 9114
        public static let http3 = Version(major: 3, minor: 0)

        // MARK: - Convenience Properties

        /// Returns true if this is HTTP/1.x
        public var isHTTP1: Bool {
            major == 1
        }

        /// Returns true if this is HTTP/2.x
        public var isHTTP2: Bool {
            major == 2
        }

        /// Returns true if this is HTTP/3.x
        public var isHTTP3: Bool {
            major == 3
        }

        // MARK: - Validation Error

        public enum ValidationError: Error, LocalizedError {
            case invalidFormat(String, reason: String)

            public var errorDescription: String? {
                switch self {
                case .invalidFormat(let value, let reason):
                    return "Invalid HTTP version '\(value)': \(reason)"
                }
            }
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_7230.HTTP.Version: ExpressibleByStringLiteral {
    /// Creates an HTTP version from a string literal
    ///
    /// Example:
    /// ```swift
    /// let version: RFC_7230.HTTPVersion = "HTTP/1.1"
    /// ```
    ///
    /// - Note: This performs validation and will trap on invalid input.
    ///   Use for known-valid literals only.
    public init(stringLiteral value: String) {
        do {
            try self.init(value)
        } catch {
            fatalError("Invalid HTTP version literal: \(value) - \(error)")
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_7230.HTTP.Version: CustomStringConvertible {
    public var description: String {
        string
    }
}

// MARK: - Codable

extension RFC_7230.HTTP.Version: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let major = try container.decode(UInt.self, forKey: .major)
        let minor = try container.decode(UInt.self, forKey: .minor)
        self.init(major: major, minor: minor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
    }

    private enum CodingKeys: String, CodingKey {
        case major
        case minor
    }
}

// MARK: - Comparable

extension RFC_7230.HTTP.Version: Comparable {
    /// Compares HTTP versions
    ///
    /// Versions are compared first by major number, then by minor number.
    public static func < (lhs: RFC_7230.HTTP.Version, rhs: RFC_7230.HTTP.Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        return lhs.minor < rhs.minor
    }
}
