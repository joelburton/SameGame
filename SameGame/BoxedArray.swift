// Swift arrays are value types, so can use a "boxed array" for clusters, since
// multiple balls share a cluster.

final class BoxedArray<T> {
    var box = [T]()
    var count: Int { self.box.count }
    var isEmpty: Bool { self.box.isEmpty }
    
    /// Add an item to the array.
    /// - Parameter item: item
    func push(_ item: T) {
        self.box.append(item)
    }
}

extension BoxedArray: Sequence {
    func makeIterator() -> Array<T>.Iterator {
        Array<T>.Iterator(_elements: self.box)
    }
}

extension BoxedArray: ExpressibleByArrayLiteral {
    /// Allow adding an array like `arr = [1, 2, 3]`
    /// - Parameter arrayLiteral: <#arrayLiteral description#>
    convenience init(arrayLiteral: Element...) {
        self.init()
        self.box.append(contentsOf: arrayLiteral)
    }
}


// don't actually need these, but playing around...
//
//extension BoxedArray: Collection {
//    var startIndex: Array<T>.Index { self.box.startIndex }
//    var endIndex: Array<T>.Index { self.box.endIndex }
//    func index(after i: Array<T>.Index) -> Array<T>.Index {self.box.index(after: i) }
//    subscript(position: Array<T>.Index) -> T {self.box[position] }
//}
//
