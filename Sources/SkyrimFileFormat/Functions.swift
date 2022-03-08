// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

enum ArgType {
    case actor(String? = nil)
    case actorValue
    case container(String? = nil)
    case faction
    case float(String? = nil)
    case integer(String? = nil)
    case topic(String? = nil)
    case quest
    case questAlias
    case scene
    case string(String? = nil)
    case variable

    case unknown(Int, String)

    static var integer: Self { .integer()}
    static var float: Self { .float()}
    static var string: Self { .string()}
    static var actor: Self { .actor()}
    static var container: Self { .container()}
    static var topic: Self { .topic() }
    
    var cast: String {
        switch self {
            case .questAlias: return "QuestAlias"
            default: return "\(self)".capitalized
        }
    }
}

//struct Function: RawRepresentable, BinaryCodable {
//    let rawValue: UInt16
//
//    static let GetEventData = Self(rawValue: 4672)
//}

struct Function {
    let id: Int
    let name: String
    let description: String?
    let abbreviation: String?
    let arguments: [ArgType]
    
    init(_ id: Int, ref: Bool = false, _ name: String, abbrev abbreviation: String? = nil, _ args: ArgType..., description: String? = nil) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.description = description
        self.arguments = args
    }
}

