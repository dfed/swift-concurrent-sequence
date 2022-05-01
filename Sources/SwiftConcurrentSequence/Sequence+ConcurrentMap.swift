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

extension Sequence {
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
        [Element](self).concurrentMap(transform)
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
        try await [Element](self).concurrentMap(transform)
    }
}
