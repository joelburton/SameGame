import SpriteKit

/** SameGame scene: manages UI and game logic. */
final class GameScene: SKScene {
    /** game grid contains ball or nil for empty slot */
    var board: OptionalMatrix<Ball>!
    var numBallsOnBoard = 0

    var scoreLabel: SKLabelNode!
    var score = (clusters: 0, bonus: 0) {
        didSet { scoreLabel.text = "Score: \(score.clusters + score.bonus)" }
    }
    var gameOverMsg: SKSpriteNode!
    var gameOver = false

    /** `cluster` is list of same-color touching balls; the current cluster is the one
     * that is selected now (if >1, is rotating visually). Cluster list is re-made after
     * any change in game board, so that (a) selecting a new cluster happens very quickly
     * in the UI and (b) we know when the game ends (there are no more >1 clusters)
     */
    var currentCluster: LinkedList<Ball> = []

    /** Set up this scene. This is only done once, regardless of number of games played. */
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
    func startGame(numCols: Int = 21, numRows: Int = 14) {
        board = OptionalMatrix(numCols: numCols, numRows: numRows) { x, y in Ball(x: x, y: y) }

        // remove existing balls on view, then add the balls on new matrix to view
        children.forEach { child in (child as? Ball)?.removeFromParent() }
        board.forEachCell { ball in self.addChild(ball) }

        currentCluster = []
        score = (clusters: 0, bonus: 0)
        gameOver = false
        numBallsOnBoard = numCols * numRows

        findClusters()
        endGameWhenNoClustersLeft()
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
            return startGame()
        }

        guard let ball = nodes(at: location).first as? Ball else { return }
        if !currentCluster.contains(ball) {
            selectCluster(x: ball.x, y: ball.y);
        } else {
            removeCluster()
        }
    }

    /** Deselect current cluster, then select clicked-on cluster and if 2+ balls, spin them */
    func selectCluster(x: Int, y: Int) {
        currentCluster.forEach { $0.stopSpin() }
        currentCluster = board[x, y]!.cluster!
        if currentCluster.count > 1 { currentCluster.forEach { $0.spin() } }
    }

    /** Find clusters (neighbors-of-same-color) on board and update clusters property.
     *
     * Called on game start, and after any board move.
     */
    func findClusters() {
        func visit(_ neighbor: Ball?, of ball: Ball) {
            // only visit real neighbors that haven't already been explored
            guard let n = neighbor, n == ball || n.cluster == nil else { return }
            if n.name == ball.name {
                // same color as us, so add to our cluster and recursively explore neighbors
                n.cluster = ball.cluster!
                ball.cluster!.push(n)

                if n.x > 0 { visit(board[n.x - 1, n.y], of: ball) }
                if n.y > 0 { visit(board[n.x, n.y - 1], of: ball) }
                if n.x < board.maxIndexX { visit(board[n.x + 1, n.y], of: ball) }
                if n.y < board.maxIndexY { visit(board[n.x, n.y + 1], of: ball) }
            }
        }

        board.forEachCell { $0.cluster = nil }
        board.forEachCell { ball in
            // if non-nil ball at x,y hasn't been examined, it's a new cluster: recursively find peers
            guard ball.cluster == nil else { return }
            ball.cluster = []
            visit(ball, of: ball)
        }
    }

    /** Remove currently-selected cluster from board. */
    func removeCluster() {
        guard currentCluster.count > 1 else { return }

        for ball in currentCluster {
            ball.removeFromParent()
            board[ball.x, ball.y] = nil
        }

        // Shift balls down when a cluster disappears and move cols left if empty.
        board.compactDownAndLeft()
        // since we moved things around, reset all balls' x/y & position to location in board grid
        board.forEachXY { x, y in if let ball = board[x, y] { ball.setPosition(x: x, y: y) } }

        numBallsOnBoard -= currentCluster.count
        // score = cluster squared (so bigger are much better) + 100pt/ball under 50 left
        score.clusters += currentCluster.count * currentCluster.count
        score.bonus = max(50 - numBallsOnBoard, 0) * 100

        currentCluster = []
        findClusters()
        endGameWhenNoClustersLeft()
    }

    /** Game is ended when there are no more clusters of 2+ balls. */
    func endGameWhenNoClustersLeft() {
        func isEmptyOrSoloCluster(ball: Ball?) -> Bool { ball == nil || ball!.cluster!.count < 2 }
        if board.allSatisfy(isEmptyOrSoloCluster) {
            gameOver = true
            gameOverMsg = SKSpriteNode(imageNamed: "gameOver")
            gameOverMsg.position = CGPoint(x: 512, y: 384)
            gameOverMsg.zPosition = 2
            self.addChild(gameOverMsg)
        }
    }

    /** Dump out board matrix for debugging. */
    func dump() {
        print("\ngridX=ballX gridY=ballY name clusterId")
        // Do y first (and in reverse order) before x so printout same arrangement as screen
        for y in board.indicesY.reversed() {
            for x in board.indicesX {
                if let b = board[x, y] {
                    print("\(x)=\(b.x!), \(y)=\(b.y!) \(b.name!) \(b.cluster!.count)")
                } else {
                    print(x, y, "-")
                }
            }
        }
    }
}
