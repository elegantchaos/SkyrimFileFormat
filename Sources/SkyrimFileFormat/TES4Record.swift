// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AsyncSequenceReader
import Bytes
import Coercion
import Foundation

private extension Tag {
    static let header: Self = "HEDR"
    static let author: Self = "CNAM"
    static let description: Self = "SNAM"
    static let master: Self = "MAST"
    static let tagifiedStringCount: Self = "INTV"
    static let unknownCounter: Self = "INCC"
    static let unusedData: Self = "DATA"
}


struct TES4Record: Codable, RecordProtocol {
    static var tag: Tag { "TES4" }
    
    let header: UnpackedHeader
    let info: TES4Header
    let desc: String
    let author: String
    let masters: [String]
    let tagifiedStringCount: UInt32
    let unknownCounter: UInt?
    let fields: [UnpackedField]?

    static func asJSON(header: RecordHeader, fields: DecodedFields, with processor: Processor) throws -> Data {
        let decoder = RecordDecoder(header: header, fields: fields)
        let record = try decoder.decode(TES4Record.self)
        return try processor.encoder.encode(record)
    }
}

