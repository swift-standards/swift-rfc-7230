# swift-rfc-7230

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift namespace types for RFC 7230: Hypertext Transfer Protocol (HTTP/1.1): Message Syntax and Routing

## Overview

This package provides Swift namespace types for HTTP/1.1 message syntax as defined in [RFC 7230](https://www.rfc-editor.org/rfc/rfc7230.html). This package defines the RFC 7230 namespace enum and Header/Body types for extension by parser implementations.

## Features

- ✅ RFC 7230 namespace enum
- ✅ Header type for parser extensions (RFC 7230 section 3.2)
- ✅ Body type for parser extensions (RFC 7230 section 3.3)
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` conformance

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-7230.git", from: "0.1.0")
]
```

## Usage

This package provides namespace types that are extended by parser implementations (e.g., swift-url-routing):

```swift
import RFC_7230

// Parser implementations extend RFC_7230.Header and RFC_7230.Body
extension RFC_7230.Header {
  public struct Parser<FieldParsers>: ParserPrinter { ... }
}

extension RFC_7230.Body {
  public struct Parser<Bytes>: ParserPrinter { ... }
}
```

## Related Packages

- [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) - Provides parser implementations

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
