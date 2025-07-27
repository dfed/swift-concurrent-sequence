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
		/// Returns an array containing the results of mapping the given closure
		/// over the sequence's elements. The given closure is executed concurrently
		/// on multiple queues to reduce the wall-time consumed by the transform.
		///
		/// - Parameter transform: A mapping closure. `transform` accepts an
		///   element of this sequence as its parameter and returns a transformed
		///   value of the same or of a different type.
		/// - Returns: An array containing the transformed elements of this
		///   sequence.
		public func concurrentMap<T: Sendable>(_ transform: @Sendable (Element) -> T) -> [T] {
			Array(self).concurrentMap(transform)
		}
	#endif

	/// Returns an array containing the results of mapping the given closure
	/// over the sequence's elements. The given closure is executed concurrently
	/// on multiple queues to reduce the wall-time consumed by the transform.
	///
	/// - Parameter transform: A mapping closure. `transform` accepts an
	///   element of this sequence as its parameter and returns a transformed
	///   value of the same or of a different type.
	/// - Returns: An array containing the transformed elements of this
	///   sequence.
	public func concurrentMap<T: Sendable>(_ transform: @escaping @Sendable (Element) async throws -> T) async rethrows -> [T] {
		try await Array(self).concurrentMap(transform)
	}
}

// MARK: - Array

extension Array where Element: Sendable {
	#if canImport(Dispatch)
		/// Returns an array containing the results of mapping the given closure
		/// over the sequence's elements. The given closure is executed concurrently
		/// on multiple queues to reduce the wall-time consumed by the transform.
		///
		/// - Parameter transform: A mapping closure. `transform` accepts an
		///   element of this sequence as its parameter and returns a transformed
		///   value of the same or of a different type.
		/// - Returns: An array containing the transformed elements of this
		///   sequence.
		public func concurrentMap<T: Sendable>(_ transform: @Sendable (Element) -> T) -> [T] {
			// Create a buffer where we can store the transformed output.
			var transformed = [T?](repeating: nil, count: count)
			// Access the underlying array memory to concurrently write to indices.
			return transformed.withUnsafeMutableBufferPointer { bufferPointer in
				let bufferHolder = UnsafeBufferHolder(buffer: bufferPointer)
				DispatchQueue.concurrentPerform(iterations: count) { index in
					// It is safe to concurrently write to unique indexes of the buffer pointer.
					bufferHolder.buffer[index] = transform(self[index])
				}
				return bufferPointer.compactMap(\.self)
			}
		}
	#endif

	/// Returns an array containing the results of mapping the given closure
	/// over the sequence's elements. The given closure is executed concurrently
	/// on multiple queues to reduce the wall-time consumed by the transform.
	///
	/// - Parameter transform: A mapping closure. `transform` accepts an
	///   element of this sequence as its parameter and returns a transformed
	///   value of the same or of a different type.
	/// - Returns: An array containing the transformed elements of this
	///   sequence.
	public func concurrentMap<T: Sendable>(_ transform: @escaping @Sendable (Element) async throws -> T) async rethrows -> [T] {
		try await withThrowingTaskGroup(
			of: IndexAndElement.self,
			returning: [T].self
		) { group in
			for index in 0..<count {
				let elementAtIndex = self[index]
				group.addTask {
					try await IndexAndElement(index: index, element: transform(elementAtIndex))
				}
			}

			var transformed = [T?](repeating: nil, count: count)
			for try await transform in group {
				transformed[transform.index] = transform.element
			}
			return transformed.compactMap(\.self)
		}
	}
}

// MARK: - IndexAndElement

private struct IndexAndElement<Element: Sendable>: Sendable {
	let index: Int
	let element: Element
}

// MARK: - UnsafeBufferHolder

private struct UnsafeBufferHolder<T: Sendable>: @unchecked Sendable {
	let buffer: UnsafeMutableBufferPointer<T?>
}
