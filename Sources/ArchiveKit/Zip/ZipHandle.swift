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

actor ZipHandle {
  let fileHandle: unzFile
  let password: String?

  init(fileURL: URL, password: String?) throws {
    guard let fileHandle = unzOpen64(fileURL.filePath) else {
      throw Archive.Error.failedToOpenArchive
    }
    self.fileHandle = fileHandle
    self.password = password
  }

  deinit {
    unzClose(fileHandle)
  }

  func contents() throws -> [ZipContent] {
    guard unzGoToFirstFile(fileHandle) == UNZ_OK else {
      throw Archive.Error.failedToReadArchive
    }
    var contents: [ZipContent] = []
    repeat {
      var info = unz_file_info64()
      guard unzGetCurrentFileInfo64(fileHandle, &info, nil, 0, nil, 0, nil, 0) == UNZ_OK else {
        throw Archive.Error.failedToReadArchive
      }

      var fileName = Array<CChar>(repeating: 0, count: Int(info.size_filename + 1))
      unzGetCurrentFileInfo64(fileHandle, nil, &fileName, info.size_filename, nil, 0, nil, 0)

      let name = String(cString: fileName)
      let content = ZipContent(
        handle: self,
        offset: unzGetOffset64(fileHandle),
        name: name,
        isHidden: name.lastPathComponent.first == ".",
        isDirectory: name.last == "/",
        compressedSize: info.compressed_size,
        uncompressedSize: info.uncompressed_size,
        crc: info.crc
      )
      contents.append(content)
    } while unzGoToNextFile(fileHandle) == UNZ_OK

    return contents
  }

  func extract(offset: Int64, upToCount count: Int) throws -> Data {
    guard unzSetOffset64(fileHandle, offset) == UNZ_OK else {
      throw Archive.Error.failedToExtractArchive
    }

    let openResult: Int32
    if let password {
      openResult = unzOpenCurrentFilePassword(fileHandle, password)
    } else {
      openResult = unzOpenCurrentFile(fileHandle)
    }
    defer {
      unzCloseCurrentFile(fileHandle)
    }

    guard openResult == UNZ_OK else {
      throw Archive.Error.failedToExtractArchive
    }
    return _readData(upToCount: count)
  }

  func checkEncrypted() -> Bool {
    unzGoToFirstFile(fileHandle)
    repeat {
      var info = unz_file_info64()
      unzGetCurrentFileInfo64(fileHandle, &info, nil, 0, nil, 0, nil, 0)
      if info.uncompressed_size > 0 {
        return info.flag & 0x01 != 0
      }
    } while unzGoToNextFile(fileHandle) == UNZ_OK
    return false
  }

  func validatePassword(_ password: String) -> Bool {
    unzGoToFirstFile(fileHandle)
    repeat {
      var info = unz_file_info64()
      unzGetCurrentFileInfo64(fileHandle, &info, nil, 0, nil, 0, nil, 0)
      if info.uncompressed_size > 0 {
        return unzOpenCurrentFilePassword(fileHandle, password) == UNZ_OK
      }
    } while unzGoToNextFile(fileHandle) == UNZ_OK
    return false
  }

  private func _readData(upToCount count: Int) -> Data {
    var data = Data(capacity: count)
    var buffer = Array<UInt8>(repeating: 0, count: min(65535, count))
    var readLength = 0
    while readLength < count {
      let length = Int(unzReadCurrentFile(fileHandle, &buffer, UInt32(buffer.count)))
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
