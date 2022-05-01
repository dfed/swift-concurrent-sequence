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

import Dispatch

extension Array {
    /// Returns an array containing the results of mapping the given closure
    /// over the sequence's elements. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the transform.
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this sequence as its parameter and returns a transformed
    ///   value of the same or of a different type.
    /// - Returns: An array containing the transformed elements of this
    ///   sequence.
    public func concurrentMap<T>(_ transform: (Element) -> T) -> [T] {
        // Create a buffer where we can store the transformed output.
        var transformed = [T?](repeating: nil, count: count)
        // Access the underlying array memory to concurrently write to indices.
        return transformed.withUnsafeMutableBufferPointer { bufferPointer in
            DispatchQueue.concurrentPerform(iterations: count) { index in
                // It is safe to concurrently write to unique indexes of the buffer pointer.
                bufferPointer[index] = transform(self[index])
            }
            return bufferPointer.compactMap { $0 }
        }
    }

    /// Returns an array containing the results of mapping the given closure
    /// over the sequence's elements. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the transform.
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this sequence as its parameter and returns a transformed
    ///   value of the same or of a different type.
    /// - Returns: An array containing the transformed elements of this
    ///   sequence.
    public func concurrentMap<T>(_ transform: @escaping (Element) throws -> T) async rethrows -> [T] {
        try await withThrowingTaskGroup(
            of: (index: Int, element: T).self,
            returning: [T].self)
        { group in
            for index in 0..<count {
                group.addTask {
                    (index, try transform(self[index]))
                }
            }

            var transformed = [T?](repeating: nil, count: count)
            for try await transform in group {
                transformed[transform.index] = transform.element
            }
            return transformed.compactMap { $0 }
        }
    }
}
