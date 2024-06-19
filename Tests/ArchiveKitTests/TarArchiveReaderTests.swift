//
//  TarArchiveReaderTests.swift
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

import XCTest
@testable import ArchiveKit

class TarArchiveReaderTests: XCTestCase {
  func testContentList() async throws {
    let reader = try Archive.read(fileURL: Resources.url("text.tar"))
    let contents = try await reader.contents()
      .filter { $0.contentType == .file && !$0.isHidden }
      .map(\.name)
    let expection: Set<String> = ["kr/텍스트1.txt", "kr/텍스트2.txt", "text1.txt", "text2.txt"]
    XCTAssertEqual(Set(contents), expection)
  }

  func testExtract() async throws {
    let reader = try Archive.read(fileURL: Resources.url("text.tar"))
    let contents = try await reader.contents()
      .filter { $0.contentType == .file && !$0.isHidden }
    var success = !contents.isEmpty
    for content in contents {
      let data = try await content.data()
      let string = String(data: data, encoding: .utf8)
      if (string ?? "") != content.name.lastPathComponent {
        success = false
      }
    }
    XCTAssertTrue(success)
  }
}
