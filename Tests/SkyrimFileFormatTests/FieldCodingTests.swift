// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import XCTest
import XCTestExtensions
@testable import SkyrimFileFormat

class FieldCodingTests: ProcessorTestCase {
    func testAlternateTexture() throws {
        let data = Data([
            0x04, 0x00, 0x00, 0x00, // size 4
            0x54, 0x65, 0x73, 0x74, // "Test"
            0x01, 0x02, 0x03, 0x04, // FormID 0x04030201
            0x0F, 0x00, 0x00, 0x00  // 3d index 0x0F
        ])
        
        let decoder = DataDecoder(data: data)
        let decoded = try decoder.decode(AlternateTextureField.AlternateTexture.self)
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.texture.id, 0x04030201)
        XCTAssertEqual(decoded.index, 0xF)
        XCTAssertEqual(decoder.remainingCount(), 0)
        
        let encoder = DataEncoder()
        let encoded = try encoder.encode(decoded)
        XCTAssertEqual(data, encoded)
        
        let json = asJSON(decoded)
        XCTAssertEqual(json,
                        """
                        {
                          "index" : 15,
                          "name" : "Test",
                          "texture" : "0x04030201"
                        }
                        """
        )
        
        let decodedFromJSON = decode(AlternateTextureField.AlternateTexture.self, fromJSON: json)
        XCTAssertEqual(decoded, decodedFromJSON)
    }
    
    func testAlternateTextures() throws {
        let data = Data([
            0x01, 0x00, 0x00, 0x00, // count 1
            0x04, 0x00, 0x00, 0x00, // size 4
            0x54, 0x65, 0x73, 0x74, // "Test"
            0x01, 0x02, 0x03, 0x04, // FormID 0x04030201
            0x0F, 0x00, 0x00, 0x00  // 3d index 0x0F
        ])
        
        let decoder = DataDecoder(data: data)
        let decoded = try decoder.decode(AlternateTextureField.self)
        XCTAssertEqual(decoded.textures.count, 1)
        let texture = decoded.textures.first!
        XCTAssertEqual(texture.name, "Test")
        XCTAssertEqual(texture.texture.id, 0x04030201)
        XCTAssertEqual(texture.index, 0xF)
        XCTAssertEqual(decoder.remainingCount(), 0)
        
        let encoder = DataEncoder()
        let encoded = try encoder.encode(decoded)
        XCTAssertEqual(data, encoded)

        let json = asJSON(decoded)
        XCTAssertEqual(json,
                        """
                        {
                          "textures" : [
                            {
                              "index" : 15,
                              "name" : "Test",
                              "texture" : "0x04030201"
                            }
                          ]
                        }
                        """
        )
        
        let decodedFromJSON = decode(AlternateTextureField.self, fromJSON: json)
        XCTAssertEqual(decoded, decodedFromJSON)

    }
}
