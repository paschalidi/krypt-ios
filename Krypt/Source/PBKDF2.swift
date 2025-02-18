//
//  PBKDF2.swift
//  NeoSwift
//
//  Created by Luís Silva on 22/09/17.
//  Copyright © 2017 drei. All rights reserved.
//
//  Source code from NeoSwift project: https://github.com/CityOfZion/neo-swift

import CommonCrypto
import Foundation

struct PBKDF2 {
  public static func deriveKey(password: [UInt8], salt: [UInt8], rounds: UInt32, keyLength: Int) -> [UInt8] {
    var result: [UInt8] = [UInt8](repeating: 0, count: keyLength)
    let data = Data(password)
    data.withUnsafeBytes { (passwordPtr: UnsafePointer<Int8>) in
      _ = CCKeyDerivationPBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),
        passwordPtr,
        password.count,
        salt,
        salt.count,
        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
        rounds,
        &result,
        keyLength
      )
    }
    return result
  }
}
