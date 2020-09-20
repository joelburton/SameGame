import SpriteKit

/** Ball in game: keeps track of its x,y position and cluster of same-color balls touching it. */
final class Ball: SKSpriteNode {
    static let colors = ["Purple", "Cyan", "Green", "Yellow", "Red"]

    var x: Int!
    var y: Int!
    var cluster: LinkedList<Ball>? = nil

    /** Make a randomly-colored ball at x, y. */
    convenience init(x: Int, y: Int) {
        let color = Self.colors.randomElement()!
        self.init(imageNamed: "ball\(color)")
        self.name = color
        self.physicsBody?.angularDamping = 0
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        setPosition(x: x, y: y)
    }

    /** Balls need to remember their own x,y on grid and be positioned visually based on that. */
    func setPosition(x: Int, y: Int) {
        self.x = x
        self.y = y
        self.position = CGPoint(x: x * 46 + 50, y: y * 46 + 50)
    }

    /** Spin continuously until manually stopped. */
    func spin() {
        self.physicsBody?.angularVelocity = 5
        self.physicsBody?.angularDamping = 0
    }

    /** Gently stop ball spinning. */
    func stopSpin() {
        self.physicsBody?.angularDamping = 3
    }
}
