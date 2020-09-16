// Swift arrays are value types, so using a reference type to hold the clusters, since multiple
// balls can share a cluster.

class BallNode {
    var ball: Ball
    var next: BallNode?

    init(ball: Ball, next: BallNode? = nil) {
        self.ball = ball
        self.next = next
    }
}

class BallLinkedList: Sequence {
    var count = 0
    var isEmpty: Bool { count == 0 }
    var head: BallNode?

    struct BallLinkedListIterator: IteratorProtocol {
        var nextNode: BallNode?

        init(_ ll: BallLinkedList) {
            self.nextNode = ll.head
        }

        mutating func next() -> Ball? {
            if nextNode == nil { return nil }

            let nextBall = nextNode!.ball
            self.nextNode = nextNode!.next
            return nextBall
        }
    }

    func makeIterator() -> BallLinkedListIterator {
        BallLinkedListIterator(self)
    }

    func push(_ ball: Ball) {
        head = BallNode(ball: ball, next: head)
        count += 1
    }
}

