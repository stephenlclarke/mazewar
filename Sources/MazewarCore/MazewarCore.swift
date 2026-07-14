import Foundation

public struct GridPoint: Codable, Hashable, Sendable {
  public let column: Int
  public let row: Int

  public init(column: Int, row: Int) {
    self.column = column
    self.row = row
  }
}

public enum Heading: String, CaseIterable, Codable, Sendable {
  case north, east, south, west

  public var turnedLeft: Heading {
    switch self {
    case .north: .west
    case .west: .south
    case .south: .east
    case .east: .north
    }
  }

  public var turnedRight: Heading {
    turnedLeft.turnedLeft.turnedLeft
  }

  public var reversed: Heading {
    turnedLeft.turnedLeft
  }

  public func moved(from point: GridPoint) -> GridPoint {
    switch self {
    case .north: GridPoint(column: point.column, row: point.row - 1)
    case .east: GridPoint(column: point.column + 1, row: point.row)
    case .south: GridPoint(column: point.column, row: point.row + 1)
    case .west: GridPoint(column: point.column - 1, row: point.row)
    }
  }

  fileprivate var wall: UInt8 { 1 << index }

  fileprivate var index: UInt8 {
    switch self {
    case .north: 0
    case .east: 1
    case .south: 2
    case .west: 3
    }
  }

  fileprivate var opposite: Heading { reversed }
}

public struct Passage: Sendable {
  public let point: GridPoint
  public let heading: Heading

  public init(from point: GridPoint, toward heading: Heading) {
    self.point = point
    self.heading = heading
  }
}

public struct Arena: Sendable {
  public let columns: Int
  public let rows: Int
  private var walls: [UInt8]

  public init(columns: Int, rows: Int, passages: [Passage] = []) {
    precondition(columns > 1 && rows > 1)
    self.columns = columns
    self.rows = rows
    walls = Array(repeating: 0b1111, count: columns * rows)
    for passage in passages where contains(passage.point) {
      let destination = passage.heading.moved(from: passage.point)
      if contains(destination) {
        open(passage)
      }
    }
  }

  public func contains(_ point: GridPoint) -> Bool {
    point.column >= 0 && point.column < columns && point.row >= 0 && point.row < rows
  }

  public func hasWall(at point: GridPoint, toward heading: Heading) -> Bool {
    walls[index(of: point)] & heading.wall != 0
  }

  public func canMove(from point: GridPoint, toward heading: Heading) -> Bool {
    contains(point) && contains(heading.moved(from: point)) && !hasWall(at: point, toward: heading)
  }

  public func hasLineOfSight(
    from origin: GridPoint, toward target: GridPoint, facing heading: Heading
  ) -> Bool {
    guard origin != target else { return false }
    var cursor = origin
    while canMove(from: cursor, toward: heading) {
      cursor = heading.moved(from: cursor)
      if cursor == target { return true }
    }
    return false
  }

  fileprivate mutating func open(_ passage: Passage) {
    let destination = passage.heading.moved(from: passage.point)
    walls[index(of: passage.point)] &= ~passage.heading.wall
    walls[index(of: destination)] &= ~passage.heading.opposite.wall
  }

  private func index(of point: GridPoint) -> Int {
    point.row * columns + point.column
  }
}

public enum ArenaGenerator {
  public static func generate(columns: Int = 24, rows: Int = 16, seed: UInt64) -> Arena {
    var arena = Arena(columns: columns, rows: rows)
    var random = SplitMix64(seed: seed)
    var visited: Set<GridPoint> = [GridPoint(column: 0, row: 0)]
    var stack = [GridPoint(column: 0, row: 0)]

    while let current = stack.last {
      let choices = Heading.allCases.filter {
        let next = $0.moved(from: current)
        return arena.contains(next) && !visited.contains(next)
      }
      guard !choices.isEmpty else {
        _ = stack.popLast()
        continue
      }
      let heading = choices[Int(random.next() % UInt64(choices.count))]
      let next = heading.moved(from: current)
      arena.open(Passage(from: current, toward: heading))
      visited.insert(next)
      stack.append(next)
    }
    return arena
  }

  public static func generate(columns: Int = 24, rows: Int = 16) -> Arena {
    generate(columns: columns, rows: rows, seed: UInt64.random(in: .min ... .max))
  }
}

public struct PlayerSnapshot: Codable, Hashable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let position: GridPoint
  public let heading: Heading
  public let score: Int

  public init(id: UUID, name: String, position: GridPoint, heading: Heading, score: Int = 0) {
    self.id = id
    self.name = name
    self.position = position
    self.heading = heading
    self.score = score
  }
}

public enum PlayerAction: Sendable {
  case forward
  case backward
  case turnLeft
  case turnRight
  case turnAround
}

public struct MatchState: Sendable {
  public let arena: Arena
  public private(set) var player: PlayerSnapshot
  public private(set) var shotsFired = 0

  public init(arena: Arena, playerName: String, playerID: UUID = UUID()) {
    self.arena = arena
    player = PlayerSnapshot(
      id: playerID, name: playerName, position: GridPoint(column: 0, row: 0), heading: .east)
  }

  @discardableResult
  public mutating func apply(_ action: PlayerAction) -> Bool {
    switch action {
    case .forward:
      return move(toward: player.heading)
    case .backward:
      return move(toward: player.heading.reversed)
    case .turnLeft:
      player = PlayerSnapshot(
        id: player.id, name: player.name, position: player.position,
        heading: player.heading.turnedLeft, score: player.score)
    case .turnRight:
      player = PlayerSnapshot(
        id: player.id, name: player.name, position: player.position,
        heading: player.heading.turnedRight, score: player.score)
    case .turnAround:
      player = PlayerSnapshot(
        id: player.id, name: player.name, position: player.position,
        heading: player.heading.reversed, score: player.score)
    }
    return true
  }

  public mutating func fire() {
    shotsFired += 1
  }

  public func canSee(_ opponent: PlayerSnapshot) -> Bool {
    arena.hasLineOfSight(from: player.position, toward: opponent.position, facing: player.heading)
  }

  private mutating func move(toward heading: Heading) -> Bool {
    guard arena.canMove(from: player.position, toward: heading) else { return false }
    player = PlayerSnapshot(
      id: player.id,
      name: player.name,
      position: heading.moved(from: player.position),
      heading: player.heading,
      score: player.score
    )
    return true
  }
}

private struct SplitMix64 {
  private var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }
}
