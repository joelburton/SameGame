// Swift arrays are value types, so using a reference type to hold the clusters, since multiple
// balls can share a cluster.

final class Node<T> {
    var item: T
    var next: Node<T>?

    init(_ item: T, next: Node? = nil) {
        self.item = item
        self.next = next
    }
}

final class LinkedList<T> {
    var count = 0
    var isEmpty: Bool { count == 0 }
    var head: Node<T>?

    func push(_ item: T) {
        head = Node<T>(item, next: head)
        count += 1
    }
}

extension LinkedList: Sequence {
    struct LinkedListIterator: IteratorProtocol {
        var nextNode: Node<T>?

        mutating func next() -> T? {
            guard let next = nextNode else { return nil }

            let nextItem = next.item
            self.nextNode = next.next
            return nextItem
        }
    }

    func makeIterator() -> LinkedListIterator {
        LinkedListIterator(nextNode: self.head)
    }
}

extension LinkedList: ExpressibleByArrayLiteral {
     convenience init(arrayLiteral: Element...) {
        self.init()
        for element in arrayLiteral {
            self.push(element)
        }
    }
}