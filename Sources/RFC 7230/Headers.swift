
// MARK: - Headers Collection

extension RFC_7230 {
    /// A collection of HTTP header fields with convenient subscript access
    ///
    /// Internally uses dictionary storage for O(1) header lookup by name.
    /// Maintains insertion order for iteration.
    ///
    /// ## Example
    /// ```swift
    /// let headers: RFC_7230.Headers = [
    ///     try .init(name: .init("Content-Type"), value: .init("application/json")),
    ///     try .init(name: .init("Authorization"), value: .init("Bearer token"))
    /// ]
    ///
    /// // Subscript access (case-insensitive, O(1))
    /// let contentType = headers["content-type"]?.first
    ///
    /// // Collection access (preserves insertion order)
    /// for header in headers {
    ///     print("\(header.name): \(header.value)")
    /// }
    /// ```
    public struct Headers: Sendable, Equatable, Hashable {
        // Internal storage: maps header name -> list of values
        // Uses OrderedDictionary to preserve insertion order for iteration
        private var storage: [Header.Field.Name: [Header.Field.Value]]

        // Ordered list of names to preserve insertion order
        private var orderedNames: [Header.Field.Name]

        /// Creates a headers collection from an array of fields
        ///
        /// - Parameter fields: The header fields
        public init(_ fields: [Header.Field] = []) {
            var storage: [Header.Field.Name: [Header.Field.Value]] = [:]
            var orderedNames: [Header.Field.Name] = []

            for field in fields {
                if storage[field.name] == nil {
                    orderedNames.append(field.name)
                    storage[field.name] = [field.value]
                } else {
                    storage[field.name]?.append(field.value)
                }
            }

            self.storage = storage
            self.orderedNames = orderedNames
        }

        /// Subscript access to header values by name (case-insensitive, O(1))
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: An array of values for that header field, or nil if not present
        ///
        /// ## Example
        /// ```swift
        /// let contentType = headers["content-type"]?.first
        /// let cookies = headers["Set-Cookie"] // All Set-Cookie values
        /// ```
        public subscript(_ name: String) -> [Header.Field.Value]? {
            storage[Header.Field.Name(name)]
        }

        /// Returns true if the headers collection is empty
        public var isEmpty: Bool {
            storage.isEmpty
        }

        /// The number of unique header names
        public var count: Int {
            storage.count
        }

        /// Appends a header field to the collection
        ///
        /// - Parameter field: The header field to append
        public mutating func append(_ field: Header.Field) {
            if storage[field.name] == nil {
                orderedNames.append(field.name)
                storage[field.name] = [field.value]
            } else {
                storage[field.name]?.append(field.value)
            }
        }

        /// Removes all header fields with the given name
        ///
        /// - Parameter name: The header field name to remove (case-insensitive)
        public mutating func removeAll(named name: String) {
            let fieldName = Header.Field.Name(name)
            storage.removeValue(forKey: fieldName)
            orderedNames.removeAll { $0 == fieldName }
        }
    }
}

// MARK: - Sequence

extension RFC_7230.Headers: Sequence {
    public struct Iterator: IteratorProtocol {
        private var nameIndex = 0
        private var valueIndex = 0
        private let orderedNames: [RFC_7230.Header.Field.Name]
        private let storage: [RFC_7230.Header.Field.Name: [RFC_7230.Header.Field.Value]]

        fileprivate init(
            orderedNames: [RFC_7230.Header.Field.Name],
            storage: [RFC_7230.Header.Field.Name: [RFC_7230.Header.Field.Value]]
        ) {
            self.orderedNames = orderedNames
            self.storage = storage
        }

        public mutating func next() -> RFC_7230.Header.Field? {
            guard nameIndex < orderedNames.count else { return nil }

            let name = orderedNames[nameIndex]
            let values = storage[name]!

            guard valueIndex < values.count else {
                nameIndex += 1
                valueIndex = 0
                return next()
            }

            let value = values[valueIndex]
            valueIndex += 1

            return RFC_7230.Header.Field(name: name, value: value)
        }
    }

    /// Iterates over all header fields (expanding headers with multiple values)
    public func makeIterator() -> Iterator {
        Iterator(orderedNames: orderedNames, storage: storage)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension RFC_7230.Headers: ExpressibleByArrayLiteral {
    /// Creates a headers collection from an array literal
    ///
    /// ## Example
    /// ```swift
    /// let headers: RFC_7230.Headers = [
    ///     try .init(name: .init("Content-Type"), value: .init("application/json"))
    /// ]
    /// ```
    public init(arrayLiteral elements: RFC_7230.Header.Field...) {
        self.init(elements)
    }
}

// MARK: - CustomStringConvertible

extension RFC_7230.Headers: CustomStringConvertible {
    public var description: String {
        map(\.description).joined(separator: "\n")
    }
}

// MARK: - Codable

extension RFC_7230.Headers: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let fields = try container.decode([RFC_7230.Header.Field].self)
        self.init(fields)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as array of fields for compatibility
        try container.encode(Array(self))
    }
}
