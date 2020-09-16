import SpriteKit

/** SameGame scene: manages UI and game logic. */
class GameScene: SKScene {
    let ballColors = ["Purple", "Cyan", "Green", "Yellow", "Red"]

    let numRows = 14
    let numCols = 21
    var numBalls = 0

    // game grid contains ball or nil for empty slot
    var grid = [[Ball?]]()

    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet { scoreLabel.text = "Score: \(score)" }
    }
    var gameOverMsg: SKSpriteNode!
    var gameOver = false

    // "cluster" is group of connected-by-color balls; the current cluster is the one
    // that is selected now (is rotating for users). All clusters are identified after
    // any change in game grid, so that (a) selecting a new cluster happens very quickly
    // in the UI and (b) we know when the game ends (there are no more greater-than-one
    // clusters).
    var currentCluster: BallLinkedList!

    /** Set up this scene. */
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = .zero

        let background = SKSpriteNode(imageNamed: "background")
        background.zPosition = -1
        background.blendMode = .replace
        background.position = CGPoint(x: 512, y: 384)
        self.addChild(background)

        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)

        startGame()
    }

    /** Start (or restart) game. */
    func startGame() {
        grid.forEach { row in row.forEach { ball in ball?.removeFromParent() } }
        grid = [[Ball?]]()

        for y in 0..<numRows {
            var row = [Ball]()
            for x in 0..<numCols {
                let color = ballColors.randomElement()!
                let ball = Ball(imageNamed: "ball\(color)")
                ball.configure(color: color, x: x, y: y)
                self.addChild(ball)
                row.append(ball)
            }
            grid.append(row)
        }

        numBalls = numRows * numCols
        findClusters()

        currentCluster = BallLinkedList()
        score = 0
        gameOver = false
    }

    /** Handle touch: selects cluster if no currently selected; otherwise, removes cluster. */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // debug state of clusters/board by touching the score label
        if nodes(at: location).first == scoreLabel {
            dump()
            return
        }

        if gameOver {
            gameOverMsg.removeFromParent()
            startGame()
        }

        guard let ball = nodes(at: location).first as? Ball else { return }
        if !currentCluster.contains(ball) {
            selectCluster(x: ball.x, y: ball.y);
        } else {
            removeCluster()
        }
    }

    /** Select cluster and spin them (deselects current cluster. */
    func selectCluster(x: Int, y: Int) {
        currentCluster.forEach { $0.stopSpin() }
        currentCluster = grid[y][x]!.cluster
        // only groups of >1 can be removed, so don't rotate clusters w/only 1 ball
        if currentCluster.count > 1 { currentCluster.forEach { $0.spin() } }
    }

    /** Find clusters (neighbors-of-same-color) on board and update clusters property.
     *
     * Called on game start, and after any board move.
     */
    func findClusters() {
        grid.forEach { row in row.forEach { ball in ball?.cluster = BallLinkedList() } }

        for y in 0..<numRows {
            for x in 0..<numCols {
                guard let ball = grid[y][x] else { continue }
                // if a ball already has a cluster, it's already fulled accounted for
                guard ball.cluster.isEmpty else { continue }

                // DFS: recursively explore neighbors, starting here
                var toVisit = [ball]
                while toVisit.count > 0 {
                    print("to visit \(ball.x) \(ball.y)")
                    let visiting = toVisit.removeLast()

                    if visiting.name == ball.name {
                        visiting.cluster = ball.cluster
                        ball.cluster.push(visiting)

                        if visiting.y > 0 {
                            if let neighbor = grid[visiting.y - 1][visiting.x] {
                                if neighbor.cluster.isEmpty { toVisit.append(neighbor) }
                            }
                        }
                        if visiting.y < numRows - 1 {
                            if let neighbor = grid[visiting.y + 1][visiting.x] {
                                if neighbor.cluster.isEmpty { toVisit.append(neighbor) }
                            }
                        }
                        if visiting.x > 0 {
                            if let neighbor = grid[visiting.y][visiting.x - 1] {
                                if neighbor.cluster.isEmpty { toVisit.append(neighbor) }
                            }
                        }
                        if visiting.x < numCols - 1 {
                            if let neighbor = grid[visiting.y][visiting.x + 1] {
                                if neighbor.cluster.isEmpty { toVisit.append(neighbor) }
                            }
                        }
                    }
                }
            }
        }
    }

    /** Remove currently-selected cluster from board. */
    func removeCluster() {
        guard currentCluster.count > 1 else { return }

        for ball in currentCluster {
            ball.removeFromParent()
            grid[ball.y][ball.x] = nil
        }

        numBalls -= currentCluster.count
        score += currentCluster.count * currentCluster.count
        if numBalls < 50 {
            score += (50 - numBalls) * 100
        }

        currentCluster = BallLinkedList()
        shiftRemainingBalls()
        findClusters()


        let allSoloClusters = grid.allSatisfy { row in
            row.allSatisfy { ball in
                ball == nil || ball!.cluster.count < 2
            }
        }

        if allSoloClusters {
            gameOver = true
            gameOverMsg = SKSpriteNode(imageNamed: "gameOver")
            gameOverMsg.position = CGPoint(x: 512, y: 384)
            gameOverMsg.zPosition = 2
            self.addChild(gameOverMsg)
        }
    }

    /** Shift balls down/over when a cluster disappears. */
    func shiftRemainingBalls() {
        // work from left-to-right (x goes down), bottom to top (y goes up)
        for x in 0..<numCols {
            var emptyStreak = 0
            for y in 0..<numRows {
                if let ball = grid[y][x] {
                    if emptyStreak > 0 {
                        grid[y][x] = nil
                        grid[y - emptyStreak][x] = ball
                        ball.setPosition(x: x, y: y - emptyStreak)
                    }
                } else {
                    emptyStreak += 1
                }
            }
        }
        // when all balls in column are gone, detect and shift everything left
        for var x in 0..<numCols {
            let col = (0..<numRows).map { y in grid[y][x] }
            if col.allSatisfy({ $0 == nil }) {
                if x < numCols - 1 {
                    for y in 0..<numRows {
                        grid[y][x] = grid[y][x + 1]
                        if let ball = grid[y][x] { ball.setPosition(x: x, y: y) }
                        grid[y][x + 1] = nil
                    }
                    // now, this row might be empty, so repeat checking it
                    x -= 1
                }
            }
        }
    }

    // debugging cluster creation & grid state:
    func dump() {
        print("\ngridX=ballX gridY=ballY name clusterId")
        for y in 0..<numRows {
            for x in 0..<numCols {
                if let b = grid[y][x] {
                    print("\(x)=\(b.x!), \(y)=\(b.y!) \(b.name!) \(b.cluster)")
                } else {
                    print(x, y, "-")
                }
            }
        }
    }
}