//
//  PEMConverter.swift
//  Krypt
//
//  Created by marko on 08.05.19.
//

import Foundation

struct PEMConverter {
  static func convertPEMToDER(_ pem: String) -> Data? {
    let possibleHeaders = PEMFormat.allCases.map { $0.header }
    let possibleFooters = PEMFormat.allCases.map { $0.footer }
    let possibleHeadersAndFooters = possibleHeaders + possibleFooters

    var stripped = ""
    pem.enumerateLines { line, _ in
      guard !possibleHeadersAndFooters.contains(line) else { return }
      stripped += line
    }
    return Data(base64Encoded: stripped)
  }

  /// Converts DER to `PKCS1`
  ///
  /// - Parameters:
  ///   - der: in PKCS1 format
  ///   - format: PEM format to return
  /// - Returns: PEM representation of DER
  static func convertDER(_ der: Data, toPEMFormat format: PEMFormat) throws -> String {
    switch format {
    case .publicPKCS1, .privatePKCS1, .certificateX509:
      let base64 = der.base64EncodedString()

      // Insert newline `\n` every 64 characters
      var index = 0
      var splits = [String]()
      while index < base64.count {
        let startIndex = base64.index(base64.startIndex, offsetBy: index)
        let endIndex = base64.index(startIndex, offsetBy: 64, limitedBy: base64.endIndex) ?? base64.endIndex
        index = endIndex.utf16Offset(in: base64)

        let chunk = String(base64[startIndex ..< endIndex])
        splits.append(chunk)
      }
      let base64WithNewlines = splits.joined(separator: "\n")
      return [format.header, base64WithNewlines, format.footer].joined(separator: "\n").appending("\n")

    case .publicPKCS8:
      let pkcs1PEM = try convertDER(der, toPEMFormat: .publicPKCS1)
      let data = Data(pkcs1PEM.utf8)
      guard let pkcs8PEM = PKCS8.convertPKCS1PEMToPKCS8PEM(data) else {
        throw PEMConverterError.invalidDERData
      }
      return pkcs8PEM
    }
  }
}

enum PEMConverterError: Error {
  case invalidPEMData
  case invalidFormat
  case invalidDERData
}

enum PEMFormat: CaseIterable {
  case privatePKCS1
  case publicPKCS1
  case publicPKCS8
  case certificateX509

  var header: String {
    switch self {
    case .privatePKCS1:
      return "-----BEGIN RSA PRIVATE KEY-----"
    case .publicPKCS1:
      return "-----BEGIN RSA PUBLIC KEY-----"
    case .publicPKCS8:
      return "-----BEGIN PUBLIC KEY-----"
    case .certificateX509:
      return "-----BEGIN CERTIFICATE-----"
    }
  }

  var footer: String {
    switch self {
    case .privatePKCS1:
      return "-----END RSA PRIVATE KEY-----"
    case .publicPKCS1:
      return "-----END RSA PUBLIC KEY-----"
    case .publicPKCS8:
      return "-----END PUBLIC KEY-----"
    case .certificateX509:
      return "-----END CERTIFICATE-----"
    }
  }
}
