// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AsyncSequenceReader
import Bytes
import Foundation

typealias FormID = UInt32
//struct FormID: Codable {
//    let id: UInt32
//}

struct ARMORecord: Codable, RecordProtocol {
    static var tag = Tag("ARMO")
    
    let _header: RecordHeader
    let _fields: UnpackedFields?

    let editorID: String
    let bounds: OBNDField
    let fullName: String?
    let maleArmour: String
    let maleInventoryImage: String?
    let maleMessageImage: String?
    let maleModelData: MODTField?
    let femaleArmour: String?
    let femaleInventoryImage: String?
    let femaleMessageImage: String?
    let femaleModelData: MODTField?
    let pickupSound: FormID
    let dropSound: FormID
    let keywordCount: UInt32
    let keywords: SingleFieldArray<FormID>
    let desc: String
    let armourRating: UInt32
    let template: FormID?
    let data: DATAField
    let armature: FormID
    let race: FormID
    let bodyTemplate: BOD2Field

    static var fieldMap = FieldTypeMap(paths: [
        (CodingKeys.editorID, \Self.editorID, "EDID"),
        (.bounds, \.bounds, "OBND"),
        (.fullName, \.fullName, "FULL"),
        (.maleArmour, \.maleArmour, "MOD2"),
        (.maleInventoryImage, \.maleInventoryImage, "ICON"),
        (.maleMessageImage, \.maleMessageImage, "MICO"),
        (.maleModelData, \.maleModelData, "MO2T"),
        (.femaleArmour, \.femaleArmour, "MOD4"),
        (.femaleInventoryImage, \.femaleInventoryImage, "ICO2"),
        (.femaleMessageImage, \.femaleMessageImage, "MIC2"),
        (.femaleModelData, \.femaleModelData, "MO4T"),
        (.pickupSound, \.pickupSound, "YNAM"),
        (.dropSound, \.dropSound, "ZNAM"),
        (.keywordCount, \.keywordCount, "KSIZ"),
        (.keywords, \.keywords, "KWDA"),
        (.desc, \.desc, "DESC"),
        (.armourRating, \.armourRating, "DNAM"),
        (.template, \.template, "TNAM"),
        (.armature, \.armature, "MODL"),
        (.data, \.data, "DATA"),
        (.race, \.race, "RNAM"),
        (.bodyTemplate, \.bodyTemplate, "BOD2")
        ]
    )
    
    func asJSON(with processor: Processor) throws -> Data {
        return try processor.encoder.encode(self)
    }
    
    struct DATAField: Codable {
        let base: UInt32
        let weight: Float
    }
}


extension ARMORecord: CustomStringConvertible {
    var description: String {
        return "«armour \(fullName ?? editorID)»"
    }
}
