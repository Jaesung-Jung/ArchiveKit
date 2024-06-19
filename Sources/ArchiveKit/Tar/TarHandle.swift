//
//  TarHandle.swift
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

actor TarHandle {
  let fileURL: URL
  let fileHandle: FileHandle

  init(fileURL: URL) throws {
    guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
      throw Archive.Error.failedToOpenArchive
    }
    self.fileURL = fileURL
    self.fileHandle = fileHandle
  }

  deinit {
    try? fileHandle.close()
  }

  func contents() throws ->[TarContent] {
    guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.filePath) else {
      throw Archive.Error.failedToReadArchive
    }
    guard let fileSize = fileAttributes[.size] as? UInt64 else {
      throw Archive.Error.failedToReadArchive
    }

    do {
      let blockSize = TarBlock.size
      var offset: UInt64 = .zero
      var contents: [TarContent] = []
      while offset < fileSize {
        try fileHandle.seek(toOffset: offset)
        guard let data = try fileHandle.read(count: blockSize) else {
          throw Archive.Error.failedToReadArchive
        }
        if let content = TarContent(block: TarBlock(data: data), handle: self, offset: offset) {
          if content.fileType != .paxHeader && content.fileType != .globalExtendedHeader {
            contents.append(content)
          }
          offset += content.blockSize
        } else {
          offset += UInt64(blockSize)
        }
      }
      return contents
    } catch {
      throw Archive.Error.failedToReadArchive
    }
  }

  func extract(offset: UInt64, upToCount count: Int) throws -> Data {
    do {
      try fileHandle.seek(toOffset: offset)
      guard let data = try fileHandle.read(count: count) else {
        throw Archive.Error.failedToExtractArchive
      }
      return data
    } catch {
      throw Archive.Error.failedToExtractArchive
    }
  }
}
