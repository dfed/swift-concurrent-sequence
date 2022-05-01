//
//  Created by Dan Federman on 4/30/22.
//  Copyright © 2022 Dan Federman.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS"BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftConcurrentSequence
import XCTest

final class ConcurrentReduceTests: XCTestCase {

    func test_array_concurrentReduce() {
        let input = Array(0..<1_000)
        let output = input.concurrentReduce(defaultValue: 0) { toUpdate, next in
            toUpdate += next
        }
        let expectedOutput = input.reduce(into: 0) { partialResult, next in
            partialResult += next
        }

        XCTAssertEqual(output, expectedOutput)
    }

    func test_dictionary_concurrentReduce() {
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

        XCTAssertEqual(output, expectedOutput)
    }

    func test_array_async_concurrentReduce() async {
        let input = Array(0..<1_000)
        let output = await input.concurrentReduce(defaultValue: 0) { lhs, rhs in lhs + rhs }
        let expectedOutput = input.reduce(into: 0) { partialResult, next in
            partialResult += next
        }

        XCTAssertEqual(output, expectedOutput)
    }

    func test_dictionary_async_concurrentReduce() async {
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

        XCTAssertEqual(output, expectedOutput)
    }

}
