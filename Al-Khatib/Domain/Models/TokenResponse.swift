//
//  TokenResponse.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String?
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case accessTokenAlt = "accessToken"
        case expiresInAlt = "expiresIn"
        case tokenTypeAlt = "tokenType"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        accessToken =
            (try? c.decode(String.self, forKey: .accessToken)) ??
            (try? c.decode(String.self, forKey: .accessTokenAlt)) ??
            ""
        
        if let intValue = try? c.decode(Int.self, forKey: .expiresIn) {
            expiresIn = intValue
        } else if let strValue = try? c.decode(String.self, forKey: .expiresIn),
                  let parsed = Int(strValue) {
            expiresIn = parsed
        } else if let intAlt = try? c.decode(Int.self, forKey: .expiresInAlt) {
            expiresIn = intAlt
        } else if let strAlt = try? c.decode(String.self, forKey: .expiresInAlt),
                  let parsedAlt = Int(strAlt) {
            expiresIn = parsedAlt
        } else {
            expiresIn = 3600
        }
        
        tokenType =
            (try? c.decode(String.self, forKey: .tokenType)) ??
            (try? c.decode(String.self, forKey: .tokenTypeAlt))
        
        if accessToken.isEmpty {
            throw DecodingError.dataCorruptedError(
                forKey: .accessToken,
                in: c,
                debugDescription: "Missing access token field in token response."
            )
        }
    }
}
