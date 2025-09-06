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

#if canImport(Dispatch)
	import Dispatch
#endif

extension Sequence where Element: Sendable {
	#if canImport(Dispatch)
		/// Returns the result of combining the elements of the sequence using the
		/// given closure. The given closure is executed concurrently
		/// on multiple queues to reduce the wall-time consumed by the reduction.
		///
		/// This synchronous method uses Grand Central Dispatch to parallelize the reduction
		/// by recursively combining pairs of elements until a single result remains.
		///
		/// Example:
		/// ```swift
		/// let numbers = [1, 2, 3, 4, 5]
		/// let sum = numbers.concurrentReduce(defaultValue: 0) { accumulator, value in
		///     accumulator += value
		/// }
		/// // Result: 15
		/// ```
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
			reducingIntoFirst: @Sendable (inout Element, Element) -> Void
		) -> Element {
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
					let bufferHolder = UnsafeBufferHolder(buffer: bufferPointer)
					// Concurrently reduce elements from `toReduce` into `reduced`.
					DispatchQueue.concurrentPerform(iterations: toReduce.count) { index in
						reducingIntoFirst(&bufferHolder.buffer[index], toReduce[index])
					}
				}
			}

			return reduced.first ?? defaultValue()
		}

		/// Returns the result of combining the elements of the sequence of dictionaries
		/// using the given closure. The given closure is executed concurrently
		/// on multiple queues to reduce the wall-time consumed by the reduction.
		///
		/// This specialized method merges dictionaries with custom conflict resolution
		/// for duplicate keys.
		///
		/// Example:
		/// ```swift
		/// let dictionaries = [
		///     ["apple": 1, "banana": 2],
		///     ["apple": 3, "cherry": 5]
		/// ]
		/// let merged = dictionaries.concurrentReduce { key, first, second in
		///     return first + second // Sum values for duplicate keys
		/// }
		/// // Result: ["apple": 4, "banana": 2, "cherry": 5]
		/// ```
		///
		/// - Parameter combine: A closure that returns the desired value for
		///   the given key when multiple values are present for the given key.
		/// - Returns: The final reduced dictionary.
		public func concurrentReduce<Key, Value>(
			combine: @Sendable (Key, Value, Value) -> Value
		) -> Element where Element == [Key: Value] {
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
	#endif

	/// Returns the result of combining the elements of the sequence using the
	/// given async closure. The given closure is executed concurrently
	/// using Swift's structured concurrency to reduce wall-time.
	///
	/// This asynchronous method uses task groups to parallelize the reduction
	/// by recursively combining pairs of elements until a single result remains.
	///
	/// Example:
	/// ```swift
	/// let files: [URL] = […]
	/// let mergedFileContents = await endpoints.concurrentReduce(defaultValue: FileContents()) { accumulated, file in
	///     try await accumulated.merge(readData(from: file))
	/// }
	/// ```
	///
	/// - Parameters:
	///   - defaultValue: A default value for Element. This value is utilized only
	///     when the receiver is empty.
	///   - reducer: A closure that combines two elements into a new reduced value.
	/// - Returns: The final reduced value. If the sequence has no elements,
	///   the result is `defaultValue`.
	public func concurrentReduce(
		defaultValue: @escaping @autoclosure () -> Element,
		_ reducer: @escaping @Sendable (Element, Element) async throws -> Element
	) async rethrows -> Element {
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
						try await reducer(toMidpoint[index], fromMidpoint[index])
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
	/// using the given async closure. The given closure is executed concurrently
	/// using Swift's structured concurrency to reduce wall-time.
	///
	/// This specialized async method merges dictionaries with custom conflict resolution
	/// for duplicate keys.
	///
	/// Example:
	/// ```swift
	/// let userGroups = await fetchUserGroups() // Returns [[String: User]]
	/// let mergedUsers = await userGroups.concurrentReduce { key, user1, user2 in
	///     // Custom logic to merge duplicate users
	///     return user1.updatedAt > user2.updatedAt ? user1 : user2
	/// }
	/// ```
	///
	/// - Parameter combine: A closure that returns the desired value for
	///   the given key when multiple values are present for the given key.
	/// - Returns: The final reduced dictionary.
	public func concurrentReduce<Key, Value>(
		combine: @escaping @Sendable (Key, Value, Value) throws -> Value
	) async rethrows -> Element where Element == [Key: Value] {
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

// MARK: - UnsafeBufferHolder

private struct UnsafeBufferHolder<T: Sendable>: @unchecked Sendable {
	let buffer: UnsafeMutableBufferPointer<T>
}
