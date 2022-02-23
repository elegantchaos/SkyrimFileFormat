// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AsyncSequenceReader
import BinaryCoding
import Bytes
import Foundation

protocol ProcessorProtocol {
    associatedtype BaseIterator: AsyncIteratorProtocol where BaseIterator.Element == Byte
    typealias Iterator = AsyncBufferedIterator<BaseIterator>
    var processor: Processor { get }
}

extension ProcessorProtocol {
    var configuration: Configuration { processor.configuration }
}

protocol RecordDataIterator: AsyncIteratorProtocol where Element == RecordData {
}

/// Performs four main operations on ESPs:
///
/// - load: takes an `.esps` bundle and returns an `ESPBundle` instance
/// - save: takes an `ESPBundle` instance and outputs an `.esps` bundle
/// - unpack: takes an `.esp` file and returns an `ESPBundle` instance
/// - pack: takes an `ESPBundle` instance and outputs an `.esp` file
/// 
class Processor {
    internal init(configuration: Configuration = .defaultConfiguration) {
        self.configuration = configuration
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
        self.binaryEncoder = DataEncoder()

        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    let configuration: Configuration
    let jsonEncoder: JSONEncoder
    let jsonDecoder: JSONDecoder
    let binaryEncoder: BinaryEncoder
    
    /// Load a bundle of records from an `.esps` directory.
    public func load(url: URL) throws -> ESPBundle {
        let records = try loadRecords(from: url)
        let name = url.deletingPathExtension().lastPathComponent
        return ESPBundle(name: name, records: records)
    }
    
    /// Save a bundle to an `.esps` directory.
    public func save(_ bundle: ESPBundle, to folder: URL) async throws {
        let url = folder.appendingPathComponent(bundle.name).appendingPathExtension(".esps")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try await save(records: bundle.records, to: url)
    }
    
    /// Unpack an `.esp` file
    public func unpack(url: URL) async throws -> ESPBundle {
        let name = url.deletingPathExtension().lastPathComponent
        return try await unpack(name: name, bytes: url.resourceBytes)
    }

    /// Unpack an `.esp` file from a byte stream
    public func unpack<I: AsyncByteSequence>(name: String, bytes: I) async throws -> ESPBundle {
        var unpacked: [RecordProtocol] = []
        for try await record in records(bytes: bytes, processChildren: true) {
            unpacked.append(record)
        }
        
        return ESPBundle(name: name, records: unpacked)
    }

    /// Pack a bundle to an `.esp` file
    public func pack(_ bundle: ESPBundle, to url: URL) throws {
        let data = try pack(bundle)
        try data.write(to: url, options: .atomic)
    }
    
    /// Pack a bundle to Data
    public func pack(_ bundle: ESPBundle) throws -> Data {
        return try save(bundle.records)
    }
    
    /// Pack a single record to Data
    public func pack(_ record: RecordProtocol) throws -> Data {
        let encoder = DataEncoder()
        try encode(record, using: encoder)
        return encoder.data
    }
}

private extension Processor {
    func recordData<I: AsyncByteSequence>(bytes: I) -> AsyncThrowingIteratorMapSequence<I, RecordData> {
        let records = bytes.iteratorMap { iterator -> RecordData in
            let stream = AsyncDataStream(iterator: iterator)
            let type = try await Tag(stream.read(UInt32.self))
            let size = try await stream.read(UInt32.self)
            let header = try await RecordHeader(type: type, stream)
            let payloadSize = Int(type == GroupRecord.tag ? size - 24 : size)
            let data = LoadedRecordData(data: try await stream.read(count: payloadSize))
            iterator = stream.iterator

            return try await RecordData(type: type, header: header, data: data)
        }

        return records
    }

    func records<I: AsyncByteSequence>(bytes: I, processChildren: Bool) -> AsyncThrowingMapSequence<AsyncThrowingIteratorMapSequence<I, RecordData>, RecordProtocol> {
        let wrapped = recordData(bytes: bytes).map { recordData in
            try await self.record(from: recordData, processChildren: processChildren)
        }
        
        return wrapped
    }

    func record(from record: RecordData, processChildren: Bool) async throws -> RecordProtocol {
        if record.isGroup {
            var children: [RecordProtocol] = []
            if processChildren {
                for try await child in recordData(bytes: record.data.asyncBytes) {
                    children.append(try await self.record(from: child, processChildren: processChildren))
                }
            }
            
            return GroupRecord(header: record.header, children: children)
        } else {
            let fields = try await decodedFields(type: record.type, header: record.header, data: record.data)
            let recordClass = configuration.recordClass(for: record.type)
            let decoder = RecordDecoder(header: record.header, fields: fields)
            return try recordClass.init(from: decoder)
        }
    }
    
    func fields<I>(bytes: inout I, types: FieldTypeMap, inRecord recordType: Tag, withHeader recordHeader: RecordHeader) -> AsyncThrowingIteratorMapSequence<I, Field> where I: AsyncSequence, I.Element == Byte {
        let sequence = bytes.iteratorMap { iterator -> Field in
            let header = try await Field.Header(&iterator)
            let data = try await iterator.next(bytes: Bytes.self, count: Int(header.size))
            return try await self.inflate(header: header, data: data, types: types, inRecord: recordType, withHeader: recordHeader)
        }
        
        return sequence
    }
    
    func decodedFields(type: Tag, header: RecordHeader, data: RecordDataProvider) async throws -> DecodedFields {
        let map = try configuration.fields(forRecord: type)
        let fp = DecodedFields(map, for: type, header: header)
        
        var bytes = data.asyncBytes
        
        let fields = fields(bytes: &bytes, types: map, inRecord: type, withHeader: header)
        for try await field in fields {
            try fp.add(field)
        }
        fp.moveUnprocesed()
        
        return fp
    }
    
    func inflate(header: Field.Header, data: Bytes, types: FieldTypeMap, inRecord recordType: Tag, withHeader recordHeader: RecordHeader) async throws -> Field {
        if let type = types.fieldType(forTag: header.type) {
            do {
                let decoder = FieldDecoder(header: header, data: data, inRecord: recordType, withHeader: recordHeader)
                decoder.enableLogging = true
                print("Unpacking field \(header.type) - \(type)")
                let unpacked = try type.init(fromBinary: decoder)
                return Field(header: header, value: unpacked)
            } catch {
                print("Unpack failed. Falling back to basic field.\n\n\(error)")
            }
        }

        return Field(header: header, value: data)
    }

    
    func save(records: [RecordProtocol], to url: URL) async throws {
        var index = 0
        for record in records {
            if let group = record as? GroupRecord {
                try await save(group: group, index: index, asJSONTo: url)
            } else {
                try await save(record: record, index: index, asJSONTo: url)
            }
            index += 1
        }
    }

    
    func save(record: RecordProtocol, index: Int, asJSONTo url: URL) async throws {
        var label = record.name
        if let identified = record as? IdentifiedRecord {
            label = "\(identified.editorID) \(label)"
        }

        let name = String(format: "%04d %@", index, label)
        let recordURL = url.appendingPathComponent(name)

        let encoded = try record.asJSON(with: self)
        try encoded.write(to: recordURL.appendingPathExtension("json"), options: .atomic)
    }
    
    
    func save(group: GroupRecord, index: Int, asJSONTo url: URL) async throws {
        let name = String(format: "%04d %@", index, group.name)
        let groupURL = url.appendingPathComponent(name).appendingPathExtension(GroupRecord.fileExtension)

        try FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true)

        let header = group.header
        let headerURL = groupURL.appendingPathComponent("header.json")
        let encoded = try jsonEncoder.encode(header)
        try encoded.write(to: headerURL, options: .atomic)

        let childrenURL = groupURL.appendingPathComponent("records")
        try FileManager.default.createDirectory(at: childrenURL, withIntermediateDirectories: true)

        try await save(records: group._children, to: childrenURL)
    }
    
    func save(_ records: [RecordProtocol]) throws -> Data {
        let binaryEncoder = DataEncoder()
        for record in records {
            try save(record, using: binaryEncoder)
        }
        
        return binaryEncoder.data
    }
    
    func save(_ record: RecordProtocol, using encoder: BinaryEncoder) throws {
        try encode(record, using: encoder)
        for child in record._children {
            try save(child, using: encoder)
        }
    }
    
    func encode(_ record: RecordProtocol, using encoder: BinaryEncoder) throws {
        let type = type(of: record).tag
        let fields = try configuration.fields(forRecord: type)
        let recordEncoder = RecordEncoder(fields: fields)
        try record.encode(to: recordEncoder)
        let encoded = recordEncoder.binaryEncoder.data

        try type.binaryEncode(to: encoder)
        let size = encoded.count - RecordHeader.binaryEncodedSize + ((type == GroupRecord.tag) ? 24 : 0)
        try UInt32(size).encode(to: encoder)
        try encoded.encode(to: encoder)
    }
    
    enum Error: Swift.Error {
        case wrongFileExtension
    }
    
    func loadRecords(from url: URL) throws -> [RecordProtocol] {
        let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

        var loaded: [RecordProtocol] = []
        let decoder = JSONDecoder()
        for url in urls {
            if url.pathExtension == GroupRecord.fileExtension {
                // handle groups
                let headerURL = url.appendingPathComponent("header.json")
                let data = try Data(contentsOf: headerURL)
                let header = try decoder.decode(RecordHeader.self, from: data)
                let contentURL = url.appendingPathComponent("records")
                let children = try loadRecords(from: contentURL)
                let group = GroupRecord(header: header, children: children)
                loaded.append(group)
            } else {
                let data = try Data(contentsOf: url)
                let stub = try decoder.decode(RecordStub.self, from: data)
                let type = configuration.recordClass(for: stub._header.type)
                do {
                    let decoded = try type.fromJSON(data, with: self)
                    loaded.append(decoded)
                } catch {
                    print("Couldn't load record \(type): \(error)")
                }
            }
        }
        
        return loaded
    }

}

struct RecordStub: Codable {
    let _header: RecordHeader
}
