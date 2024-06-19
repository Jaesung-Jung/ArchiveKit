//
//  TarBlock.swift
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

// MARK: - TarBlock

struct TarBlock {
  static let size = 512

  let data: Data
  let trimmingCharacterSet = CharacterSet.whitespaces.union(CharacterSet(["\0"]))

  @inlinable var isValid: Bool { data.count == TarBlock.size }

  @inlinable func read(_ type: String.Type, for position: Position) -> String? {
    return String(data: data[position.range], encoding: .utf8)
      .flatMap { $0.trimmingCharacters(in: trimmingCharacterSet) }
  }

  @inlinable func read(_ type: Date.Type, for position: Position) -> Date? {
    return read(Int.self, for: position).map { Date(timeIntervalSince1970: TimeInterval($0)) }
  }

  @inlinable func read<T>(_ type: T.Type, for position: Position) -> T? where T: FixedWidthInteger {
    return read(String.self, for: position).flatMap { T($0, radix: 8) }
  }

  @inlinable func read<T: RawRepresentable>(_ type: T.Type, for position: Position) -> T? where T.RawValue == String {
    return read(String.self, for: position).flatMap { T(rawValue: $0) }
  }

  @inlinable func read<T: RawRepresentable>(_ type: T.Type, for position: Position) -> T? where T.RawValue: FixedWidthInteger {
    return read(T.RawValue.self, for: position).flatMap { T(rawValue: $0) }
  }
}

// MARK: - TarBlock.Position

extension TarBlock {
  struct Position {
    let offset: Int
    let size: Int
    @inlinable var range: Range<Int> { offset..<(offset + size) }

    static let name = Position(offset: 0, size: 100)
    static let mode = Position(offset: 100, size: 8)
    static let uid = Position(offset: 108, size: 8)
    static let gid = Position(offset: 116, size: 8)
    static let size = Position(offset: 124, size: 12)
    static let mtime = Position(offset: 136, size: 12)
    static let chksum = Position(offset: 148, size: 8)
    static let typeflag = Position(offset: 156, size: 1)
    static let linkname = Position(offset: 157, size: 100)
    static let magic = Position(offset: 257, size: 6)
    static let version = Position(offset: 263, size: 2)
    static let uname = Position(offset: 265, size: 32)
    static let gname = Position(offset: 297, size: 32)
    static let devmajor = Position(offset: 329, size: 8)
    static let devminor = Position(offset: 337, size: 8)
  }
}
