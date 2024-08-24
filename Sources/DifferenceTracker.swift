// https://github.com/GilesHammond/DifferenceTracker
//
// MIT License
//
// Copyright (c) 2022 Giles Hammond
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

private typealias RemainingRemovalTracker = [Int: Int]

/*
 CollectionDifference Changes are ordered: removals high->low, insertions low->high.
 RemainingRemovalTracker is used to track the position of items left in the collection, but that
 are assumed absent in the offsets provided for later insertions.
 */
private extension RemainingRemovalTracker {
    mutating func addSkippedRemoval(atOffset offset: Int) {
        self[offset] = offset
    }

    mutating func useSkippedRemoval(withOriginalOffset originalOffset: Int) -> Int {
        let currentOffset = removeValue(forKey: originalOffset)!
        removalMade(at: currentOffset)
        return currentOffset
    }

    mutating func removalMade(at offset: Int) {
        forEach { key, value in
            if value > offset {
                self[key] = value - 1
            }
        }
    }

    mutating func insertionMade(at offset: Int) {
        forEach { key, value in
            if value >= offset {
                self[key] = value + 1
            }
        }
    }

    func adjustedInsertion(withOriginalOffset originalOffset: Int) -> Int {
        var adjustedOffset = originalOffset

        for offset in values.sorted() {
            if offset <= adjustedOffset {
                adjustedOffset += 1
            }
        }

        return adjustedOffset
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension CollectionDifference where ChangeElement: Hashable {
    enum ChangeStep {
        case insert(_ element: ChangeElement, at: Int)
        case remove(_ element: ChangeElement, at: Int)
        case move(_ element: ChangeElement, from: Int, to: Int)

        var isMove: Bool {
            switch self {
            case .move:
                return true
            case .insert, .remove:
                return false
            }
        }
    }

    var steps: [ChangeStep] {
        guard !isEmpty else { return [] }

        var steps: [ChangeStep] = []
        var offsetTracker = RemainingRemovalTracker()

        for change in inferringMoves() {
            switch change {
            case let .remove(offset, element, associatedWith):
                if associatedWith != nil {
                    offsetTracker.addSkippedRemoval(atOffset: offset)
                } else {
                    steps.append(.remove(element, at: offset))
                    offsetTracker.removalMade(at: offset)
                }

            case let .insert(offset, element, associatedWith):
                if let associatedWith = associatedWith {
                    let from = offsetTracker.useSkippedRemoval(withOriginalOffset: associatedWith)
                    let to = offsetTracker.adjustedInsertion(withOriginalOffset: offset)
                    steps.append(.move(element, from: from, to: to))
                    offsetTracker.insertionMade(at: to)
                } else {
                    let to = offsetTracker.adjustedInsertion(withOriginalOffset: offset)
                    steps.append(.insert(element, at: to))
                    offsetTracker.insertionMade(at: to)
                }
            }
        }

        return steps
    }
}
