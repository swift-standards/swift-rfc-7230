import RFC_3986
import RFC_7231

// MARK: - RFC 7230 HTTP Message Namespace

extension RFC_7230 {
    /// HTTP message namespace
    public enum Message {}
}

// MARK: - HTTP Request Message

extension RFC_7230.Message {
    /// HTTP request message per RFC 7230
    ///
    /// This is the RFC-accurate, type-safe representation of an HTTP request.
    /// It models the complete request-line (method + request-target + HTTP-version),
    /// header fields, and optional message body.
    ///
    /// ## Example
    /// ```swift
    /// // Create a GET request to an origin server
    /// let request = RFC_7230.Message.Request.Domain(
    ///     method: .get,
    ///     requestTarget: .origin(
    ///         path: try .init("/api/users"),
    ///         query: try .init("page=1")
    ///     ),
    ///     headers: [
    ///         try .init(
    ///             name: .init("Accept"),
    ///             value: .init("application/json")
    ///         )
    ///     ]
    /// )
    ///
    /// // Create a POST request with body
    /// let post = RFC_7230.Message.Request.Domain(
    ///     method: .post,
    ///     requestTarget: .origin(path: try .init("/api/users"), query: nil),
    ///     headers: [
    ///         try .init(name: .init("Content-Type"), value: .init("application/json"))
    ///     ],
    ///     body: jsonData
    /// )
    /// ```
    ///
    /// ## RFC 7230 Reference
    /// ```
    /// HTTP-message = start-line
    ///                *( header-field CRLF )
    ///                CRLF
    ///                [ message-body ]
    ///
    /// start-line = request-line / status-line
    ///
    /// request-line = method SP request-target SP HTTP-version CRLF
    /// ```
    public struct Request: Sendable, Equatable, Hashable {
        // MARK: - Request Line Components

        /// HTTP method (required per RFC 7230)
        ///
        /// The method token indicates the request method to be performed on the target resource.
        public var method: RFC_7231.Method

        /// Request-target (required per RFC 7230)
        ///
        /// The request-target identifies the resource upon which to apply the request.
        /// See `Target` for the four forms defined by RFC 7230.
        public var requestTarget: Target

        /// HTTP protocol version (required per RFC 7230)
        ///
        /// The HTTP-version indicates the protocol version being used.
        /// Defaults to HTTP/1.1 per modern HTTP semantics.
        public var httpVersion: RFC_7230.HTTP.Version

        // MARK: - Message Components

        /// Header fields (case-insensitive per RFC 7230)
        ///
        /// Each header field consists of a case-insensitive field name followed by a
        /// colon (":"), optional leading whitespace, the field value, and optional trailing whitespace.
        ///
        /// Use subscript for convenient access: `request.headers["content-type"]?.first`
        public var headers: RFC_7230.Headers

        /// Message body (optional)
        ///
        /// The message body (if any) of an HTTP message is used to carry the payload body
        /// of that request or response.
        public var body: Data?

        // MARK: - Initialization

        /// Creates an HTTP request message
        ///
        /// - Parameters:
        ///   - method: The HTTP method (required)
        ///   - requestTarget: The request-target (required)
        ///   - httpVersion: The HTTP version (defaults to HTTP/1.1)
        ///   - headers: The header fields (defaults to empty)
        ///   - body: The message body (optional)
        public init(
            method: RFC_7231.Method,
            requestTarget: Target,
            httpVersion: RFC_7230.HTTP.Version = .http11,
            headers: RFC_7230.Headers = [],
            body: Data? = nil
        ) {
            self.method = method
            self.requestTarget = requestTarget
            self.httpVersion = httpVersion
            self.headers = headers
            self.body = body
        }

        /// Convenience initializer that constructs requestTarget from individual RFC components
        ///
        /// This initializer provides a more ergonomic API for constructing requests by
        /// accepting individual typed URI components and building the correct request-target.
        ///
        /// - Parameters:
        ///   - method: The HTTP method (defaults to GET)
        ///   - scheme: The URI scheme. If provided with host, creates absolute-form target
        ///   - userinfo: The userinfo component
        ///   - host: The host. If provided with scheme, creates absolute-form target
        ///   - port: The port number
        ///   - path: The path component. Defaults to root path "/"
        ///   - query: The query component
        ///   - httpVersion: The HTTP version (defaults to HTTP/1.1)
        ///   - headers: The header fields (defaults to empty)
        ///   - body: The message body (optional)
        public init(
            method: RFC_7231.Method = .get,
            scheme: RFC_3986.URI.Scheme? = nil,
            userinfo: RFC_3986.URI.Userinfo? = nil,
            host: RFC_3986.URI.Host? = nil,
            port: RFC_3986.URI.Port? = nil,
            path: RFC_3986.URI.Path = "/",
            query: RFC_3986.URI.Query? = nil,
            httpVersion: RFC_7230.HTTP.Version = .http11,
            headers: RFC_7230.Headers = [],
            body: Data? = nil
        ) {
            // Determine request target form based on components
            let requestTarget: Target

            if let scheme = scheme, let host = host {
                // Absolute-form: construct URI from components
                let authority = RFC_3986.URI.Authority(
                    userinfo: userinfo,
                    host: host,
                    port: port
                )

                let uri = RFC_3986.URI(
                    scheme: scheme,
                    authority: authority,
                    path: path,
                    query: query,
                    fragment: nil
                )

                requestTarget = .absolute(uri)
            } else {
                // Origin-form: just path and query
                requestTarget = .origin(path: path, query: query)
            }

            self.init(
                method: method,
                requestTarget: requestTarget,
                httpVersion: httpVersion,
                headers: headers,
                body: body
            )
        }

        // MARK: - Convenience Accessors

        /// Gets the value(s) of a header field by name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: An array of values for that header field
        ///
        /// Header field names are case-insensitive per RFC 7230 Section 3.2.
        ///
        /// - Note: Consider using `headers["name"]` subscript for more convenient access.
        public func header(_ name: RFC_7230.Header.Field.Name) -> [RFC_7230.Header.Field.Value] {
            headers[name.rawValue] ?? []
        }

        /// Gets the first value of a header field by name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: The first value for that header field, or nil if not present
        ///
        /// - Note: Consider using `headers["name"]?.first` for more convenient access.
        public func firstHeader(_ name: RFC_7230.Header.Field.Name) -> RFC_7230.Header.Field.Value? {
            headers[name.rawValue]?.first
        }

        /// Adds a header field
        ///
        /// - Parameter field: The header field to add
        /// - Returns: A new request with the header field added
        public func addingHeader(_ field: RFC_7230.Header.Field) -> Request {
            var copy = self
            copy.headers.append(field)
            return copy
        }

        /// Removes all header fields with the given name
        ///
        /// - Parameter name: The header field name to remove (case-insensitive)
        /// - Returns: A new request with the header fields removed
        public func removingHeaders(_ name: RFC_7230.Header.Field.Name) -> Request {
            var copy = self
            copy.headers.removeAll(named: name.rawValue)
            return copy
        }

        // MARK: - Convenience Accessors for Request Target Components

        /// Path component from the request target, if applicable
        ///
        /// Returns the path for origin-form and absolute-form request targets.
        /// Returns nil for authority-form and asterisk-form.
        ///
        /// ## Example
        /// ```swift
        /// // origin-form: /users/123
        /// request.path // RFC_3986.URI.Path("/users/123")
        ///
        /// // absolute-form: http://example.com/api/users
        /// request.path // RFC_3986.URI.Path("/api/users")
        ///
        /// // authority-form: example.com:80 (CONNECT)
        /// request.path // nil
        /// ```
        public var path: RFC_3986.URI.Path? {
            switch requestTarget {
            case .origin(let path, _):
                return path
            case .absolute(let uri):
                return uri.path.flatMap { try? RFC_3986.URI.Path($0) }
            case .authority, .asterisk:
                return nil
            }
        }

        /// Query component from the request target, if applicable
        ///
        /// Returns the query for origin-form and absolute-form request targets.
        /// Returns nil for authority-form, asterisk-form, or when no query is present.
        public var query: RFC_3986.URI.Query? {
            switch requestTarget {
            case .origin(_, let query):
                return query
            case .absolute(let uri):
                return uri.query.flatMap { try? RFC_3986.URI.Query($0) }
            case .authority, .asterisk:
                return nil
            }
        }

        /// Scheme component from the request target, if applicable
        ///
        /// Returns the scheme for absolute-form request targets.
        /// Returns nil for other forms (scheme comes from connection context).
        public var scheme: RFC_3986.URI.Scheme? {
            guard case .absolute(let uri) = requestTarget,
                  let schemeString = uri.scheme else {
                return nil
            }
            return try? RFC_3986.URI.Scheme(schemeString)
        }

        /// Authority component from the request target, if applicable
        ///
        /// Returns the authority for absolute-form and authority-form request targets.
        /// Returns nil for origin-form and asterisk-form.
        public var authority: RFC_3986.URI.Authority? {
            switch requestTarget {
            case .absolute(let uri):
                // Try to construct authority from URI components
                guard let host = uri.host,
                      let hostEnum = try? RFC_3986.URI.Host(host) else {
                    return nil
                }
                let port = uri.port.flatMap { UInt16(exactly: $0) }.map { RFC_3986.URI.Port($0) }
                return RFC_3986.URI.Authority(
                    userinfo: uri.userinfo,
                    host: hostEnum,
                    port: port
                )
            case .authority(let authority):
                return authority
            case .origin, .asterisk:
                return nil
            }
        }

        /// Host component from the request target, if applicable
        ///
        /// Returns the host for absolute-form and authority-form request targets.
        /// Returns nil for origin-form and asterisk-form.
        ///
        /// This is a convenience accessor that extracts the host from the authority.
        public var host: RFC_3986.URI.Host? {
            authority?.host
        }

        /// Fragment component from the request target, if applicable
        ///
        /// Returns the fragment for absolute-form request targets.
        /// Returns nil for other forms or when no fragment is present.
        ///
        /// Note: Fragments are not typically sent in HTTP requests per RFC 7230,
        /// but may be present when parsing URLs.
        public var fragment: String? {
            guard case .absolute(let uri) = requestTarget else {
                return nil
            }
            return uri.fragment
        }

        // MARK: - Request Line

        /// The request-line as it would appear in an HTTP message
        ///
        /// Example: "GET /index.html HTTP/1.1"
        public var requestLine: String {
            "\(method.rawValue) \(requestTarget.rawValue) \(httpVersion.string)"
        }

        // MARK: - Validation

        /// Validates that the request is well-formed according to RFC 7230
        ///
        /// - Throws: `ValidationError` if the request is invalid
        public func validate() throws {
            // Validate method compatibility with request-target form
            switch requestTarget {
            case .authority:
                // authority-form is only used with CONNECT
                guard method == .connect else {
                    throw ValidationError.invalidMethodForTarget(
                        method: method,
                        target: requestTarget,
                        reason: "authority-form can only be used with CONNECT method"
                    )
                }

            case .asterisk:
                // asterisk-form is only used with OPTIONS
                guard method == .options else {
                    throw ValidationError.invalidMethodForTarget(
                        method: method,
                        target: requestTarget,
                        reason: "asterisk-form can only be used with OPTIONS method"
                    )
                }

            default:
                break
            }

            // Validate headers
            for header in headers {
                // Header validation is already done in Header.Field.Value initialization
                // Additional request-specific header validation could go here
            }

            // Validate body presence with method
            if let body = body, !body.isEmpty {
                // Per RFC 7230, some methods SHOULD NOT have a body
                if method.isSafe {
                    // Safe methods (GET, HEAD, OPTIONS, TRACE) typically don't have bodies
                    // This is not an error, but may warrant a warning in some contexts
                }
            }
        }

        // MARK: - Validation Error

        public enum ValidationError: Error, LocalizedError {
            case invalidMethodForTarget(
                method: RFC_7231.Method,
                target: Target,
                reason: String
            )

            public var errorDescription: String? {
                switch self {
                case .invalidMethodForTarget(let method, let target, let reason):
                    return "Invalid method '\(method.rawValue)' for request-target '\(target)': \(reason)"
                }
            }
        }
    }
}

// MARK: - Codable

extension RFC_7230.Message.Request: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(RFC_7231.Method.self, forKey: .method)
        let requestTarget = try container.decode(Target.self, forKey: .requestTarget)
        let httpVersion = try container.decodeIfPresent(RFC_7230.HTTP.Version.self, forKey: .httpVersion)
            ?? .http11
        let headers = try container.decodeIfPresent(RFC_7230.Headers.self, forKey: .headers)
            ?? []
        let body = try container.decodeIfPresent(Data.self, forKey: .body)

        self.init(
            method: method,
            requestTarget: requestTarget,
            httpVersion: httpVersion,
            headers: headers,
            body: body
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(method, forKey: .method)
        try container.encode(requestTarget, forKey: .requestTarget)
        try container.encode(httpVersion, forKey: .httpVersion)
        if !headers.isEmpty {
            try container.encode(Array(headers), forKey: .headers)
        }
        if let body = body {
            try container.encode(body, forKey: .body)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case method
        case requestTarget
        case httpVersion
        case headers
        case body
    }
}

// MARK: - CustomStringConvertible

extension RFC_7230.Message.Request: CustomStringConvertible {
    public var description: String {
        var result = requestLine
        for header in headers {
            result += "\n\(header.description)"
        }
        if let body = body {
            result += "\n\n[Body: \(body.count) bytes]"
        }
        return result
    }
}
