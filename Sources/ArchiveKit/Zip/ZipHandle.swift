//
//  ZipHandle.swift
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
import minizip407

struct ZipHandle {
  let fileURL: URL
  let password: String?

  init(fileURL: URL, password: String?) {
    self.fileURL = fileURL
    self.password = password
  }

  func contents() throws -> [ZipContent] {
    return try _openArchive { handle in
      guard unzGoToFirstFile(handle) == UNZ_OK else {
        throw Archive.Error.failedToReadArchive
      }
      var contents: [ZipContent] = []
      repeat {
        var info = unz_file_info64()
        guard unzGetCurrentFileInfo64(handle, &info, nil, 0, nil, 0, nil, 0) == UNZ_OK else {
          throw Archive.Error.failedToReadArchive
        }

        var fileName = Array<CChar>(repeating: 0, count: Int(info.size_filename + 1))
        unzGetCurrentFileInfo64(handle, nil, &fileName, info.size_filename, nil, 0, nil, 0)

        let name = String(cString: fileName)
        let content = ZipContent(
          handle: self,
          offset: unzGetOffset64(handle),
          name: name,
          isHidden: name.lastPathComponent.first == ".",
          isDirectory: name.last == "/",
          compressedSize: info.compressed_size,
          uncompressedSize: info.uncompressed_size,
          crc: info.crc
        )
        contents.append(content)
      } while unzGoToNextFile(handle) == UNZ_OK

      return contents
    }
  }

  func extract(offset: Int64, upToCount count: Int) throws -> Data {
    return try _openArchive { handle in
      guard unzSetOffset64(handle, offset) == UNZ_OK else {
        throw Archive.Error.failedToExtractArchive
      }

      let openResult: Int32
      if let password {
        openResult = unzOpenCurrentFilePassword(handle, password)
      } else {
        openResult = unzOpenCurrentFile(handle)
      }
      defer {
        unzCloseCurrentFile(handle)
      }

      guard openResult == UNZ_OK else {
        throw Archive.Error.failedToExtractArchive
      }
      return _readData(handle: handle, upToCount: count)
    }
  }

  func checkEncrypted() -> Bool {
    let result = try? _openArchive { handle in
      unzGoToFirstFile(handle)
      repeat {
        var info = unz_file_info64()
        unzGetCurrentFileInfo64(handle, &info, nil, 0, nil, 0, nil, 0)
        if info.uncompressed_size > 0 {
          return info.flag & 0x01 != 0
        }
      } while unzGoToNextFile(handle) == UNZ_OK
      return false
    }
    return result ?? false
  }

  func validatePassword(_ password: String) -> Bool {
    let result = try? _openArchive { handle in
      unzGoToFirstFile(handle)
      repeat {
        var info = unz_file_info64()
        unzGetCurrentFileInfo64(handle, &info, nil, 0, nil, 0, nil, 0)
        if info.uncompressed_size > 0 {
          return unzOpenCurrentFilePassword(handle, password) == UNZ_OK
        }
      } while unzGoToNextFile(handle) == UNZ_OK
      return false
    }
    return result ?? false
  }

  private func _openArchive<Result>(_ handler: (unzFile) throws -> Result) throws -> Result {
    guard let handle = unzOpen64(fileURL.filePath) else {
      throw Archive.Error.failedToOpenArchive
    }
    defer {
      unzClose(handle)
    }
    return try handler(handle)
  }

  private func _readData(handle: unzFile, upToCount count: Int) -> Data {
    var data = Data(capacity: count)
    var buffer = Array<UInt8>(repeating: 0, count: min(65535, count))
    var readLength = 0
    while readLength < count {
      let length = Int(unzReadCurrentFile(handle, &buffer, UInt32(buffer.count)))
      if length > 0 {
        data.append(Data(bytes: &buffer, count: length))
        readLength += length
      } else {
        return data
      }
    }
    return data
  }
}
