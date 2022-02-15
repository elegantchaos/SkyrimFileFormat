// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AsyncSequenceReader
import Bytes
import Foundation

extension String {
    init(hexForBytes bytes: Bytes) {
        self.init(bytes.map({ String(format: "%02X", $0)}).joined(separator: ""))
    }

    init(hexForData data: Data) {
        self.init(data.map({ String(format: "%02X", $0)}).joined(separator: ""))
    }
}

struct Field: CustomStringConvertible {
    let header: Header
    let value: Any

    var description: String {
        return "«\(header.type) field»"
    }
    
    var encodedValue: String {
        let data = value as? Bytes ?? []
        return String(hexForBytes: data)
    }
}

extension Field {
    struct Header: Codable {
        let type: Tag
        let size: UInt16

        init(type: Tag, size: UInt16) {
            self.type = type
            self.size = size
        }
        
        init<S: AsyncIteratorProtocol>(_ iterator: inout AsyncBufferedIterator<S>) async throws where S.Element == UInt8 {
            let tag = try await iterator.next(littleEndian: UInt32.self)
            self.type = Tag(tag)
            self.size = try await iterator.next(littleEndian: UInt16.self)
        }
    }
}
