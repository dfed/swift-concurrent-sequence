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

extension Sequence {

    /// Returns the result of combining the elements of the sequence using the
    /// given closure. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the reduction.
    ///
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on an
    /// array of integers to filter adjacent equal entries or count frequencies.
    ///
    /// - Parameters:
    ///   - defaultValue: A default value for Element. This value is utilized only
    ///     when the receiver is empty.
    ///   - reducingIntoFirst: A closure that combines an accumulating value and
    ///     an element of the sequence into a new reduced value, to be used
    ///     in the next call of the `reducingIntoFirst` closure or returned to
    ///     the caller.
    /// - Returns: The final reduced value. If the sequence has no elements,
    ///   the result is `defaultValue`.
    public func concurrentReduce(
        defaultValue: @autoclosure () -> Element,
        reducingIntoFirst: (inout Element, Element) -> ())
    -> Element
    {
        var reduced = [Element](self)
        while reduced.count > 1 {
            // We can reduce any two elements concurrently, so split the reduced array into two.
            let reducedCount = reduced.count
            let midpoint = reducedCount / 2

            // The array `toReduce` is always the same size as (or smaller by one element than) the `reduced` array.
            let toReduce = Array(reduced[0..<midpoint])
            reduced = Array(reduced[midpoint..<reducedCount])

            // Access the underlying array memory to concurrently write to unique indices.
            reduced.withUnsafeMutableBufferPointer { bufferPointer in
                // Concurrently reduce elements from `toReduce` into `reduced`.
                DispatchQueue.concurrentPerform(iterations: toReduce.count) { index in
                    reducingIntoFirst(&bufferPointer[index], toReduce[index])
                }
            }
        }

        return reduced.first ?? defaultValue()
    }

    /// Returns the result of combining the elements of the sequence of dictionaries
    /// using the given closure. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the reduction.
    ///
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on an
    /// array of integers to filter adjacent equal entries or count frequencies.
    ///
    /// - Parameters:
    ///   - defaultValue: A default value for Element. This value is utilized only
    ///     when the receiver is empty.
    ///   - combine: A closure that returns the desired value for
    ///     the given key when multiple values are present for the given key.
    /// - Returns: The final reduced value. If the sequence has no elements,
    ///   the result is `defaultValue`.
    public func concurrentReduce<Key, Value>(
        combine: (Key, Value, Value) -> Value)
    -> Element
    where Element == [Key: Value]
    {
        concurrentReduce(defaultValue: Element()) { updating, next in
            for (key, nextValue) in next {
                if let existingValue = updating[key] {
                    updating[key] = combine(key, existingValue, nextValue)
                } else {
                    updating[key] = nextValue
                }
            }
        }
    }

    /// Returns the result of combining the elements of the sequence using the
    /// given closure. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the reduction.
    ///
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on an
    /// array of integers to filter adjacent equal entries or count frequencies.
    ///
    /// - Parameters:
    ///   - defaultValue: A default value for Element. This value is utilized only
    ///     when the receiver is empty.
    ///   - reducingIntoFirst: A closure that combines an accumulating value and
    ///     an element of the sequence into a new reduced value, to be used
    ///     in the next call of the `reducingIntoFirst` closure or returned to
    ///     the caller.
    /// - Returns: The final reduced value. If the sequence has no elements,
    ///   the result is `defaultValue`.
    public func concurrentReduce(
        defaultValue: @escaping @autoclosure () -> Element,
        _ reducer: @escaping (Element, Element) throws -> Element)
    async rethrows
    -> Element
    {
        try await withThrowingTaskGroup(of: Element.self) { group in
            var reduced = [Element](self)
            while reduced.count > 1 {
                // We can reduce any two elements concurrently, so split the reduced array into two.
                let reducedCount = reduced.count
                let midpoint = reducedCount / 2

                // The array `toMidpoint` is always the same size as (or smaller by one element than) the `fromMidpoint` array.
                let toMidpoint = Array(reduced[0..<midpoint])
                let fromMidpoint = Array(reduced[midpoint..<reducedCount])

                // Concurrently reduce elements from identical indexes on both arrays.
                for index in 0..<toMidpoint.count {
                    group.addTask {
                        try reducer(toMidpoint[index], fromMidpoint[index])
                    }
                }

                reduced = [Element]()
                reduced.reserveCapacity(fromMidpoint.count)
                for try await reducedElement in group {
                    reduced.append(reducedElement)
                }

                if midpoint < fromMidpoint.count, let last = fromMidpoint.last {
                    reduced.append(last)
                }
            }

            return reduced.first ?? defaultValue()
        }
    }

    /// Returns the result of combining the elements of the sequence of dictionaries
    /// using the given closure. The given closure is executed concurrently
    /// on multiple queues to reduce the wall-time consumed by the reduction.
    ///
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on an
    /// array of integers to filter adjacent equal entries or count frequencies.
    ///
    /// - Parameters:
    ///   - defaultValue: A default value for Element. This value is utilized only
    ///     when the receiver is empty.
    ///   - combine: A closure that returns the desired value for
    ///     the given key when multiple values are present for the given key.
    /// - Returns: The final reduced value. If the sequence has no elements,
    ///   the result is `defaultValue`.
    public func concurrentReduce<Key, Value>(
        combine: @escaping (Key, Value, Value) throws -> Value)
    async rethrows
    -> Element
    where Element == [Key: Value]
    {
        try await concurrentReduce(defaultValue: Element()) { lhs, rhs in
            var reduced = lhs
            for (key, nextValue) in rhs {
                if let existingValue = lhs[key] {
                    reduced[key] = try combine(key, existingValue, nextValue)
                } else {
                    reduced[key] = nextValue
                }
            }
            return reduced
        }
    }

}
