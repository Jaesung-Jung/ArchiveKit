//
//  Archive.swift
//
//  Copyright © 2024 Jaesung Jung. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

// MARK: - Archive

public class Archive {
  private init() {
  }

  public static func read(fileURL: URL, password: String? = nil) throws -> Reader {
    do {
      guard let format = try Format.allCases.first(where: { try $0.isValid(fileURL: fileURL) }) else {
        throw Archive.Error.unsupportedFileFormat
      }
      switch format {
      case .zip:
        return try ZipReader(fileURL: fileURL)
      case .tar:
        return TarReader(fileURL: fileURL)
      }
    } catch {
      throw Archive.Error.failedToOpenArchive
    }
  }
}

// MARK: - Archive.ArchiveType

extension Archive {
  public enum Format: CaseIterable {
    case tar
    case zip

    func isValid(fileURL: URL) throws -> Bool {
      switch self {
      case .tar:
        let fileExtension = fileURL.pathExtension.lowercased()
        let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.filePath)[.size] as? UInt64
        return fileExtension == "tar" && fileSize.map { $0 > 0 && ($0 % 512) == 0 } ?? false
      case .zip:
        return try hasSignature(
          fileURL: fileURL,
          signatures: [
            Data([0x50, 0x4B, 0x03, 0x04]),
            Data([0x50, 0x4B, 0x05, 0x06]), // empty archive
            Data([0x50, 0x4B, 0x07, 0x08])  // spanned archive
          ]
        )
//      case .rar:
//        return try hasSignature(
//          fileURL: fileURL,
//          signatures: [
//            Data([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00]),       // RAR 1.5 to 4.0
//            Data([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00])  // RAR 5+
//          ]
//        )
//      case .sevenz:
//        return try hasSignature(
//          fileURL: fileURL,
//          signatures: [
//            Data([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])
//          ]
//        )
      }
    }

    func hasSignature(fileURL: URL, signatures: [Data]) throws -> Bool {
      guard let maxCount = signatures.map(\.count).max() else {
        return false
      }
      let handle = try FileHandle(forReadingFrom: fileURL)
      let data = try handle.read(count: maxCount)
      guard let data, data.count == maxCount else {
        return false
      }
      return signatures.contains {
        data.prefix($0.count) == $0
      }
    }
  }
}

// MARK: - Archive.ContentType

extension Archive {
  public enum ContentType {
    case directory
    case file
    case symbolicLink
    case unknown
  }
}

// MARK: - Archive.Content

extension Archive {
  public protocol Content {
    var name: String { get }
    var size: UInt64 { get }
    var isHidden: Bool { get }
    var contentType: ContentType { get }
    var format: Format { get }

    func data() async throws -> Data
    func data(upToCount: Int) async throws -> Data
    func write(to url: URL) async throws
  }
}

// MARK: - Archive.Error

extension Archive {
  public enum Error: Swift.Error {
    case unsupportedFileFormat

    case failedToOpenArchive
    case failedToReadArchive
    case failedToExtractArchive
  }
}
