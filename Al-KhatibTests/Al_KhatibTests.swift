//
//  Al_KhatibTests.swift
//  Al-KhatibTests
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Testing
@testable import Al_Khatib

struct Al_KhatibTests {

    @Test func randomAyahPayloadDecodesTajweedField() throws {
        let json = """
        {
          "verse_key": "2:172",
          "text_uthmani_tajweed": "يَ<tajweed class=madda_obligatory>ـٰٓ</tajweed>أَيُّهَا"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let payload = try decoder.decode(RandomAyahPayload.self, from: json)
        #expect(payload.textUthmaniTajweed?.contains("tajweed") == true)
        #expect(payload.tajweedWebHTMLFragment().contains("tajweed"))
    }

}
