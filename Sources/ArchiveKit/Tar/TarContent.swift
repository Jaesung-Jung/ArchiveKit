//
//  TarContent.swift
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

// MARK: - TarContent

struct TarContent: Archive.Content {
  let handle: TarHandle
  let offset: UInt64

  let name: String
  let mode: Permission
  let uid: Int
  let gid: Int
  let size: UInt64
  let mtime: Date
  let checksum: Int
  let fileType: FileType
  let linkName: String
  let magic: String
  let version: String
  let userName: String
  let groupName: String

  let isHidden: Bool
  var contentType: Archive.ContentType
  var format: Archive.Format { .tar }

  @inlinable var dataOffset: UInt64 { offset + 512 }

  @inlinable var dataBlockSize: UInt64 {
    if size % 512 == .zero {
      return size
    }
    return (size / 512 + 1) * 512
  }

  @inlinable var blockSize: UInt64 {
    dataBlockSize + 512
  }

  init?(block: TarBlock, handle: TarHandle, offset: UInt64) {
    guard block.isValid else {
      return nil
    }
    guard let size = block.read(UInt64.self, for: .size), let type = block.read(FileType.self, for: .typeflag) else {
      return nil
    }
    guard type != .regularFile || (type == .regularFile && size > 0) else {
      return nil
    }
    guard let name = block.read(String.self, for: .name), !name.isEmpty else {
      return nil
    }

    self.handle = handle
    self.offset = offset
    self.name = name
    self.mode = block.read(Permission.self, for: .mode) ?? Permission(rawValue: 0)
    self.uid = block.read(Int.self, for: .uid) ?? 0
    self.gid = block.read(Int.self, for: .gid) ?? 0
    self.size = size
    self.mtime = block.read(Date.self, for: .mtime) ?? Date(timeIntervalSince1970: 0)
    self.checksum = block.read(Int.self, for: .chksum) ?? 0
    self.fileType = type
    self.linkName = block.read(String.self, for: .linkname) ?? ""
    self.magic = block.read(String.self, for: .magic) ?? ""
    self.version = block.read(String.self, for: .version) ?? ""
    self.userName = block.read(String.self, for: .uname) ?? ""
    self.groupName = block.read(String.self, for: .gname) ?? ""
    self.isHidden = name.lastPathComponent.first == "."
    switch type {
    case .regularFile:
      self.contentType = .file
    case .symbolicLink:
      self.contentType = .symbolicLink
    case .directory:
      self.contentType = .directory
    default:
      self.contentType = .unknown
    }
  }

  func data() async throws -> Data {
    return try await handle.extract(offset: dataOffset, upToCount: Int(size))
  }

  func data(upToCount count: Int) async throws -> Data {
    return try await handle.extract(offset: dataOffset, upToCount: min(count, Int(dataBlockSize)))
  }

  func write(to url: URL) async throws {
  }
}

// MARK: - TarContent.Permission

extension TarContent {
  struct Permission: OptionSet {
    let rawValue: Int

    static let ownerRead = Permission(rawValue: 0o400)
    static let ownerWrite = Permission(rawValue: 0o200)
    static let ownerExecute = Permission(rawValue: 0o100)
    static let groupRead = Permission(rawValue: 0o40)
    static let groupWrite = Permission(rawValue: 0o20)
    static let groupExecute = Permission(rawValue: 0o10)
    static let otherRead = Permission(rawValue: 0o4)
    static let otherWrite = Permission(rawValue: 0o2)
    static let otherExecute = Permission(rawValue: 0o1)

    init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
}

// MARK: - TarContent.FileType

extension TarContent {
  enum FileType: String {
    case regularFile
    case hardLink
    case symbolicLink
    case characterSpecial
    case blockSpecial
    case directory
    case fifoSpecial
    case paxHeader
    case globalExtendedHeader
    case reserved

    init?(rawValue: String) {
      switch rawValue {
      case "0", "\0":
        self = .regularFile
      case "1":
        self = .hardLink
      case "2":
        self = .symbolicLink
      case "3":
        self = .characterSpecial
      case "4":
        self = .blockSpecial
      case "5":
        self = .directory
      case "6":
        self = .fifoSpecial
      case "x":
        self = .paxHeader
      case "g":
        self = .globalExtendedHeader
      default:
        self = .reserved
      }
    }
  }
}
