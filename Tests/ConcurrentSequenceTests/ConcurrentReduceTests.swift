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

import ConcurrentSequence
import Testing

struct ConcurrentReduceTests {
	@Test
	func array_concurrentReduce() {
		let input = Array(0..<1_000)
		let output = input.concurrentReduce(defaultValue: 0) { toUpdate, next in
			toUpdate += next
		}
		let expectedOutput = input.reduce(into: 0) { partialResult, next in
			partialResult += next
		}

		#expect(output == expectedOutput)
	}

	@Test
	func dictionary_concurrentReduce() {
		let input = (0..<1_000).map {
			(0...$0)
				.reduce(into: [String: Int]()) { partialResult, next in
					partialResult["\(next)"] = 1
				}
		}
		let output = input.concurrentReduce { _, lhs, rhs in lhs + rhs }
		let expectedOutput = (0..<1_000).reduce(into: [String: Int]()) { partialResult, next in
			partialResult["\(next)"] = 1_000 - next
		}

		#expect(output == expectedOutput)
	}

	@Test
	func array_async_concurrentReduce() async {
		let input = Array(0..<1_000)
		let output = await input.concurrentReduce(defaultValue: 0) { lhs, rhs in lhs + rhs }
		let expectedOutput = input.reduce(into: 0) { partialResult, next in
			partialResult += next
		}

		#expect(output == expectedOutput)
	}

	@Test
	func dictionary_async_concurrentReduce() async {
		let input = (0..<1_000).map {
			(0...$0)
				.reduce(into: [String: Int]()) { partialResult, next in
					partialResult["\(next)"] = 1
				}
		}
		let output = await input.concurrentReduce { _, lhs, rhs in lhs + rhs }
		let expectedOutput = (0..<1_000).reduce(into: [String: Int]()) { partialResult, next in
			partialResult["\(next)"] = 1_000 - next
		}

		#expect(output == expectedOutput)
	}
}
