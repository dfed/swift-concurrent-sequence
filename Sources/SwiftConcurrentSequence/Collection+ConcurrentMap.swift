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

#if canImport(Dispatch)
import Dispatch
#endif

public extension Collection where Element: Sendable {
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
	func concurrentMap<T: Sendable>(_ transform: @Sendable (Element) -> T) -> [T] {
		// Create a buffer where we can store the transformed output.
		var transformed = [T?](repeating: nil, count: count)
		let initialCollection = Array(self)
		// Access the underlying array memory to concurrently write to indices.
		return transformed.withUnsafeMutableBufferPointer { bufferPointer in
			let bufferHolder = UnsafeBufferHolder(buffer: bufferPointer)
			DispatchQueue.concurrentPerform(iterations: count) { index in
				// It is safe to concurrently write to unique indexes of the buffer pointer.
				bufferHolder.buffer[index] = transform(initialCollection[index])
			}
			return bufferPointer.compactMap { $0 }
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
	func concurrentMap<T: Sendable>(_ transform: @escaping @Sendable (Element) throws -> T) async rethrows -> [T] {
		try await withThrowingTaskGroup(
			of: IndexAndElement.self,
			returning: [T].self
		) { group in
			let initialCollection = Array(self)
			for index in 0 ..< count {
				let elementAtIndex = initialCollection[index]
				group.addTask {
					try IndexAndElement(index: index, element: transform(elementAtIndex))
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

private struct IndexAndElement<Element: Sendable>: Sendable {
	let index: Int
	let element: Element
}

private struct UnsafeBufferHolder<T: Sendable>: @unchecked Sendable {
	let buffer: UnsafeMutableBufferPointer<T?>
}
