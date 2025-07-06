// MIT License
//
// Copyright (c) 2025 Dan Federman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import SwiftConcurrentSequence
import XCTest

final class ConcurrentMapTests: XCTestCase {
	func test_array_concurrentMap() {
		let output = Array(0..<10_000).concurrentMap { $0 + 1 }
		XCTAssertEqual(
			output,
			Array(1..<10_001)
		)
	}

	func test_set_concurrentMap() {
		let output = Set(Set(0..<10_000).concurrentMap { $0 + 1 })
		XCTAssertEqual(
			output,
			Set(1..<10_001)
		)
	}

	func test_array_async_concurrentMap() async {
		let output = await Array(0..<10_000).concurrentMap { $0 + 1 }
		XCTAssertEqual(
			output,
			Array(1..<10_001)
		)
	}

	func test_set_async_concurrentMap() async {
		let output = await Set(Set(0..<10_000).concurrentMap { $0 + 1 })
		XCTAssertEqual(
			output,
			Set(1..<10_001)
		)
	}
}
