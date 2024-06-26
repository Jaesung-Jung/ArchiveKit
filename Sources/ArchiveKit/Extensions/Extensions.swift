//
//  Extensions.swift
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

// MARK: - FileHandle

extension FileHandle {
  @inlinable func read(count: Int) throws -> Data? {
    if #available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, tvOS 13.4, visionOS 1.0, watchOS 6.2, *) {
      return try read(upToCount: count)
    } else {
      return readData(ofLength: count)
    }
  }
}
// MARK: - URL

extension URL {
  @inlinable var filePath: String {
    if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      return path(percentEncoded: false)
    } else {
      return path
    }
  }
}

// MARK: - StringProtocol

extension StringProtocol {
  @inlinable var lastPathComponent: SubSequence {
    guard let targetIndex = lastIndex(of: "/") else {
      return self[startIndex...]
    }
    return self[index(after: targetIndex)...]
  }
}
