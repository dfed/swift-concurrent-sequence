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

final class ConcurrentMapTests: XCTestCase {
    func test_array_concurrentMap() {
        let output = Array(0 ..< 10000).concurrentMap { $0 + 1 }
        XCTAssertEqual(
            output,
            Array(1 ..< 10001)
        )
    }

    func test_set_concurrentMap() {
        let output = Set(Set(0 ..< 10000).concurrentMap { $0 + 1 })
        XCTAssertEqual(
            output,
            Set(1 ..< 10001)
        )
    }

    func test_array_async_concurrentMap() async {
        let output = await Array(0 ..< 10000).concurrentMap { $0 + 1 }
        XCTAssertEqual(
            output,
            Array(1 ..< 10001)
        )
    }

    func test_set_async_concurrentMap() async {
        let output = await Set(Set(0 ..< 10000).concurrentMap { $0 + 1 })
        XCTAssertEqual(
            output,
            Set(1 ..< 10001)
        )
    }
}
