// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bytes
import Foundation

enum RecordEncodingError: Error {
    case unknownField
}

class RecordEncoder: Encoder, WriteableRecordStream {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    var binaryEncoder: BinaryEncoder
    let configuration: Configuration
    var fieldMap: FieldTypeMap?
    
    init(binaryEncoder: BinaryEncoder, configuration: Configuration) {
        self.codingPath = []
        self.userInfo = [:]
        self.binaryEncoder = binaryEncoder
        self.configuration = configuration
        self.fieldMap = nil
    }
    
    func encode<T: Encodable>(_ value: T) throws -> Data {
        return try binaryEncoder.encode(value)
    }
    
    func startingRecord(_ header: RecordHeader) {
        fieldMap = try? configuration.fields(forRecord: Tag(header.type))
    }
                                            
    func writeInt<Value>(_ value: Value) where Value: FixedWidthInteger {
        binaryEncoder.writeInt(value)
    }
    
    func writeFloat<Value>(_ value: Value) throws where Value: BinaryFloatingPoint {
        try binaryEncoder.writeFloat(value)
    }
    
    func write(_ value: Bool) throws {
        try binaryEncoder.write(value)
    }
    
    func write(_ value: String) throws {
        try binaryEncoder.write(value)
    }
    
    func writeEncodable<Value>(_ value: Value) throws where Value: Encodable {
        print(Value.self)
        try binaryEncoder.writeEncodable(value)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer(for: self, path: codingPath))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainer(for: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainer(for: self, path: codingPath)
    }
    
    struct UnkeyedContainer: UnkeyedEncodingContainer, WriteableRecordStreamEncodingAdaptor {
        var codingPath: [CodingKey]
        var stream: WriteableRecordStream
        var count: Int
        
        init(for encoder: WriteableRecordStream) {
            self.stream = encoder
            self.codingPath = []
            self.count = 0
        }
    }
    
    struct SingleValueContainer: SingleValueEncodingContainer, WriteableRecordStreamEncodingAdaptor {
        var codingPath: [CodingKey]
        var stream: WriteableRecordStream
        
        init(for encoder: WriteableRecordStream, path codingPath: [CodingKey]) {
            self.stream = encoder
            self.codingPath = codingPath
        }
    }
    
    struct KeyedContainer<K>: KeyedEncodingContainerProtocol where K: CodingKey {
        typealias Key = K

        var codingPath: [CodingKey]
        var encoder: RecordEncoder
        
        init(for encoder: RecordEncoder, path codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        mutating func encodeNil(forKey key: K) throws {
            fatalError("to do")
        }
        
        mutating func encode(_ value: Bool, forKey key: K) throws {
            try encoder.write(value)
        }
        
        mutating func encode(_ value: String, forKey key: K) throws {
            try encoder.write(value)
        }
        
        mutating func encode(_ value: Double, forKey key: K) throws {
            try encoder.writeFloat(value)
        }
        
        mutating func encode(_ value: Float, forKey key: K) throws {
            try encoder.writeFloat(value)
        }
        
        mutating func encode(_ value: Int, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: Int8, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: Int16, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: Int32, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: Int64, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: UInt, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: UInt8, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: UInt16, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: UInt32, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode(_ value: UInt64, forKey key: K) throws {
            encoder.writeInt(value)
        }
        
        mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
            switch key.stringValue {
                case "_header":
                    encoder.startingRecord(value as! RecordHeader)
                    try encoder.writeEncodable(value)

                default:
                    print(key.stringValue)
                    guard let tag = encoder.fieldMap?.fieldTag(forKey: key) else {
                        throw RecordEncodingError.unknownField
                    }
                    let header = Field.Header(type: tag, size: 0)
                    try encoder.writeEncodable(header)
                    try encoder.writeEncodable(value)
            }
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("to do")
        }
        
        mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            fatalError("to do")
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError("to do")
        }
        
        mutating func superEncoder(forKey key: K) -> Encoder {
            fatalError("to do")
        }
        
        
        
    }
}


protocol WriteableRecordStream {
    func writeInt<Value>(_ value: Value) where Value: FixedWidthInteger
    func writeFloat<Value>(_ value: Value) throws where Value: BinaryFloatingPoint
    func write(_ value: Bool) throws
    func write(_ value: String) throws
    func writeEncodable<Value>(_ value: Value) throws where Value: Encodable
}

protocol WriteableRecordStreamEncodingAdaptor {
    var stream: WriteableRecordStream { get }
}

extension WriteableRecordStreamEncodingAdaptor {
    mutating func encodeNil() throws {
        fatalError("to do")
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError("to do")
    }
    
    mutating func encode(_ value: String) throws {
        fatalError("to do")
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError("to do")
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError("to do")
    }
    
    mutating func encode(_ value: Int) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: Int16) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: Int32) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: UInt16) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: UInt32) throws {
        stream.writeInt(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        stream.writeInt(value)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try stream.writeEncodable(value)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("to do")
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("to do")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("to do")
    }
    

}
