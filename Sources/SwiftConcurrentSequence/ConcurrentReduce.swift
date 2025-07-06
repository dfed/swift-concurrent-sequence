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
	#endif

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
		_ reducer: @escaping @Sendable (Element, Element) throws -> Element
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

private struct UnsafeBufferHolder<T: Sendable>: @unchecked Sendable {
	let buffer: UnsafeMutableBufferPointer<T>
}
