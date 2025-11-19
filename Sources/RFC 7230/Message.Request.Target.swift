import RFC_3986

// MARK: - Request Target

extension RFC_7230.Message.Request {
    /// Request-target per RFC 7230 Section 5.3
    ///
    /// The request-target identifies the resource upon which to apply the request.
    /// There are four distinct forms, each serving different purposes.
    ///
    /// ## Example
    /// ```swift
    /// // origin-form (most common, used for requests to origin servers)
    /// let origin = RFC_7230.Message.Request.Target.origin(
    ///     path: try .init("/users/123"),
    ///     query: try .init("page=1")
    /// )
    ///
    /// // absolute-form (used in requests to proxies)
    /// let absolute = RFC_7230.Message.Request.Target.absolute(
    ///     try .init("http://www.example.org/pub/WWW/TheProject.html")
    /// )
    ///
    /// // authority-form (used only with CONNECT)
    /// let authority = RFC_7230.Message.Request.Target.authority(
    ///     try .init(host: .init("www.example.com"), port: 80)
    /// )
    ///
    /// // asterisk-form (used only with OPTIONS)
    /// let asterisk = RFC_7230.Message.Request.Target.asterisk
    /// ```
    ///
    /// ## RFC 7230 Reference
    /// ```
    /// request-target = origin-form
    ///                / absolute-form
    ///                / authority-form
    ///                / asterisk-form
    ///
    /// origin-form    = absolute-path [ "?" query ]
    /// absolute-form  = absolute-URI
    /// authority-form = authority
    /// asterisk-form  = "*"
    /// ```
    public enum Target: Sendable, Equatable, Hashable {
        /// origin-form: absolute-path [ "?" query ]
        ///
        /// The most common form of request-target, used in requests directly to an origin server.
        /// Consists of the absolute path and optional query component.
        ///
        /// Example: "/where?q=now"
        ///
        /// This form is used when the request is made directly to the origin server and
        /// the client knows the authority from the connection context.
        case origin(path: RFC_3986.URI.Path, query: RFC_3986.URI.Query?)

        /// absolute-form: absolute-URI
        ///
        /// Used in requests to proxies, particularly for HTTP requests.
        /// Contains the complete URI including scheme and authority.
        ///
        /// Example: "http://www.example.org/pub/WWW/TheProject.html"
        ///
        /// A proxy is requested to service the request from a valid cache, if available,
        /// or make the same request on the client's behalf to the origin server.
        case absolute(RFC_3986.URI)

        /// authority-form: authority
        ///
        /// Used only with the CONNECT method to establish a tunnel through one or more proxies.
        /// Contains only the authority (host and port).
        ///
        /// Example: "www.example.com:80"
        ///
        /// Per RFC 7230, the authority-form is only used for CONNECT requests.
        case authority(RFC_3986.URI.Authority)

        /// asterisk-form: "*"
        ///
        /// Used only with the OPTIONS method to represent the server as a whole,
        /// rather than a specific resource.
        ///
        /// Example: "OPTIONS * HTTP/1.1"
        ///
        /// This form is used when the client wants information about the server's
        /// capabilities in general, rather than a specific resource.
        case asterisk

        /// The string representation of the request-target
        ///
        /// Returns the request-target as it would appear in an HTTP request line.
        public var rawValue: String {
            switch self {
            case .origin(let path, let query):
                if let query = query, !query.isEmpty {
                    return "\(path.string)?\(query.string)"
                } else {
                    return path.string
                }

            case .absolute(let uri):
                return uri.value

            case .authority(let authority):
                return authority.rawValue

            case .asterisk:
                return "*"
            }
        }

        /// Returns the path component, if applicable
        ///
        /// For origin-form, returns the path.
        /// For absolute-form, attempts to extract the path from the URI.
        /// For authority-form and asterisk-form, returns nil.
        public var path: RFC_3986.URI.Path? {
            switch self {
            case .origin(let path, _):
                return path

            case .absolute(let uri):
                // Try to extract path from URI
                if let pathString = uri.path {
                    return try? RFC_3986.URI.Path(pathString)
                }
                return nil

            case .authority, .asterisk:
                return nil
            }
        }

        /// Returns the query component, if applicable
        ///
        /// For origin-form, returns the query.
        /// For absolute-form, attempts to extract the query from the URI.
        /// For authority-form and asterisk-form, returns nil.
        public var query: RFC_3986.URI.Query? {
            switch self {
            case .origin(_, let query):
                return query

            case .absolute(let uri):
                // Try to extract query from URI
                if let queryString = uri.query {
                    return try? RFC_3986.URI.Query(queryString)
                }
                return nil

            case .authority, .asterisk:
                return nil
            }
        }

        /// Returns true if this is origin-form
        public var isOriginForm: Bool {
            if case .origin = self { return true }
            return false
        }

        /// Returns true if this is absolute-form
        public var isAbsoluteForm: Bool {
            if case .absolute = self { return true }
            return false
        }

        /// Returns true if this is authority-form
        public var isAuthorityForm: Bool {
            if case .authority = self { return true }
            return false
        }

        /// Returns true if this is asterisk-form
        public var isAsteriskForm: Bool {
            if case .asterisk = self { return true }
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_7230.Message.Request.Target: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_7230.Message.Request.Target: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let form = try container.decode(String.self, forKey: .form)

        switch form {
        case "origin":
            let path = try container.decode(RFC_3986.URI.Path.self, forKey: .path)
            let query = try container.decodeIfPresent(RFC_3986.URI.Query.self, forKey: .query)
            self = .origin(path: path, query: query)

        case "absolute":
            let uriString = try container.decode(String.self, forKey: .uri)
            let uri = try RFC_3986.URI(uriString)
            self = .absolute(uri)

        case "authority":
            let authority = try container.decode(RFC_3986.URI.Authority.self, forKey: .authority)
            self = .authority(authority)

        case "asterisk":
            self = .asterisk

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .form,
                in: container,
                debugDescription: "Unknown request-target form: \(form)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .origin(let path, let query):
            try container.encode("origin", forKey: .form)
            try container.encode(path, forKey: .path)
            if let query = query {
                try container.encode(query, forKey: .query)
            }

        case .absolute(let uri):
            try container.encode("absolute", forKey: .form)
            try container.encode(uri.value, forKey: .uri)

        case .authority(let authority):
            try container.encode("authority", forKey: .form)
            try container.encode(authority, forKey: .authority)

        case .asterisk:
            try container.encode("asterisk", forKey: .form)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case form
        case path
        case query
        case uri
        case authority
    }
}
