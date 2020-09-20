/** A matrix type where each cell can be of type T or optional. */

class OptionalMatrix<T> {
    // Paws off this internal implementation detail, dog
    private var grid: [[T?]]

    var indicesX: Range<Int> { grid.indices }
    var indicesY: Range<Int> { grid[0].indices }
    var maxIndexX: Int { grid.count - 1 }
    var maxIndexY: Int { grid[0].count - 1 }

    subscript(x: Int, y: Int) -> T? {
        get { grid[x][y] }
        set { grid[x][y] = newValue }
    }

    /** Make matrix, using body function to determine value of each cell. */
    init(numCols: Int, numRows: Int, body: (_ x: Int, _ y: Int) -> T) {
        precondition(numCols > 0 && numRows > 0, "Matrix cannot have 0 length or height")
        grid = (0..<numCols).map { x in (0..<numRows).map { y in body(x, y) } }
    }

    /** Call callback with x, y for each cell (nil or otherwise). */
    func forEachXY(_ body: (_ x: Int, _ y: Int) -> ()) {
        indicesX.forEach { x in indicesY.forEach { y in body(x, y) } }
    }

    /** Call callback with each non-nil cell. */
    func forEachCell(_ body: (_ cell: T) -> ()) {
        grid.forEach { col in col.forEach { cell in if let cell = cell { body(cell) } } }
    }

    /** Do all cells satisfy this condition? */
    func allSatisfy(_ predicate: (_ item: T?) -> Bool) -> Bool {
        grid.allSatisfy { col in col.allSatisfy(predicate) }
    }

    /** Grow a column at the end (by adding nil cells) */
    func growColWithNils(atX: Int, to: Int) {
        grid[atX] += Array(repeating: nil, count: to - grid[atX].count)
    }

    /** Compact non-nil cells downward; do same for left moving of all-nil cols. */
    func compactDownAndLeft() {
        grid = grid.map { col in col.filter { $0 != nil } }
        // equalize height of cols in matrix to height of highest col
        let newMaxColHeight = grid.max { $1.count > $0.count }!.count
        self.indicesX.forEach { x in growColWithNils(atX: x, to: newMaxColHeight) }

        // when all cells in column are nil, shift col left (shortens matrix width)
        grid = grid.filter { col in col.contains { ball in ball != nil } }
    }
}
