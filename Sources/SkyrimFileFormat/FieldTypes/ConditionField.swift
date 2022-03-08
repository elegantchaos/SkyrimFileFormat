// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BinaryCoding


struct ConditionField: Codable {
    public enum CodingKeys: CodingKey {
        case test
        case flags
    }

    let raw: RawConditionField
    
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "not implemented yet"))
    }

    func encode(to encoder: Encoder) throws {
        let expression = Expression(function: raw.function, value: raw.value, comparison: raw.op, flags: raw.flags, parameters: raw.params, runOn: raw.runOn)
        if raw.flags.rawValue != 0 {
            var container = encoder.container(keyedBy: Self.CodingKeys)
            try container.encode(expression.rawValue, forKey: .test)
            try container.encode(raw.flags, forKey: .flags)
        } else {
            var container = encoder.unkeyedContainer()
            try container.encode(expression.rawValue)
        }
    }
}

extension ConditionField: BinaryCodable {
    init(fromBinary decoder: BinaryDecoder) throws {
        var container = try decoder.unkeyedContainer()
        self.raw = try container.decode(RawConditionField.self)
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(raw)

    }
}

struct RawConditionField: BinaryCodable {
    let opCode: UInt8
    let padding1: Padding3
    let value: UInt32
    let function: UInt16
    let padding2: UInt16
    let param1: UInt32
    let param2: UInt32
    let runOn: ConditionTarget
    let reference: FormID
    let unknown: UInt32
    
    var params: [UInt32] {
        var parameters: [UInt32] = []
        
        if function == 4672 /* GetEventData */ {
            parameters.append(param1 & 0xFFFF)
            parameters.append(param1 >> 16)
        } else {
            parameters.append(param1)
        }
        
        parameters.append(param2)
        return parameters
    }
    
    var op: ComparisonOperator {
        return ComparisonOperator(flags: opCode)
    }
    
    var flags: ConditionFlags {
        return ConditionFlags(rawValue: opCode & 0x1F)
    }
}
