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

  public var turnedRight: Heading { turnedLeft.turnedLeft.turnedLeft }
  public var reversed: Heading { turnedLeft.turnedLeft }

  public func moved(from point: GridPoint) -> GridPoint {
    switch self {
    case .north: GridPoint(column: point.column, row: point.row - 1)
    case .east: GridPoint(column: point.column + 1, row: point.row)
    case .south: GridPoint(column: point.column, row: point.row + 1)
    case .west: GridPoint(column: point.column - 1, row: point.row)
    }
  }
}

public struct Arena: Sendable {
  public let columns: Int
  public let rows: Int
  private let walls: Set<GridPoint>

  public init(columns: Int, rows: Int, walls: Set<GridPoint> = []) {
    precondition(columns > 1 && rows > 1)
    self.columns = columns
    self.rows = rows
    self.walls = walls
  }

  public func contains(_ point: GridPoint) -> Bool {
    point.column >= 0 && point.column < columns && point.row >= 0 && point.row < rows
  }

  public func isWall(at point: GridPoint) -> Bool {
    !contains(point) || walls.contains(point)
  }

  public func canMove(from point: GridPoint, toward heading: Heading) -> Bool {
    contains(point) && !isWall(at: heading.moved(from: point))
  }

  public func hasLineOfSight(
    from origin: GridPoint, toward target: GridPoint, facing heading: Heading
  ) -> Bool {
    guard origin != target else { return false }
    var cursor = heading.moved(from: origin)
    while contains(cursor) && !isWall(at: cursor) {
      if cursor == target { return true }
      cursor = heading.moved(from: cursor)
    }
    return false
  }

  public func openPoints() -> [GridPoint] {
    (0..<rows).flatMap { row in
      (0..<columns).compactMap { column in
        let point = GridPoint(column: column, row: row)
        return isWall(at: point) ? nil : point
      }
    }
  }

  /// The exact 32-by-16 maze bitmap from the retained 1986 Unix/X11 source.
  public static let original: Arena = {
    let sourceColumns = [
      "1111111111111111", "1000000000000001", "1011111011110111", "1000001010000001",
      "1010100010111101", "1011101010100001", "1000001000101101", "1111101110000001",
      "1000000010111101", "1011111010100001", "1000001000101111", "1011101010100001",
      "1000001010111101", "1011111010110101", "1000000000000001", "1011111110101111",
      "1000100000100001", "1110101010101101", "1000101010100101", "1011101010110001",
      "1000000010100101", "1011111110101101", "1000100010100101", "1010101010110001",
      "1010101010000101", "1010101010101101", "1010101010100101", "1010001010110101",
      "1010101000100001", "1010101010111101", "1000100010000101", "1111111111111111",
    ]
    var walls: Set<GridPoint> = []
    for (column, sourceColumn) in sourceColumns.enumerated() {
      let bits = Array(sourceColumn)
      for row in 0..<bits.count where bits[bits.count - 1 - row] == "1" {
        walls.insert(GridPoint(column: column, row: row))
      }
    }
    return Arena(columns: sourceColumns.count, rows: sourceColumns[0].count, walls: walls)
  }()
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

public struct Viewpoint: Codable, Hashable, Sendable {
  public let position: GridPoint
  public let heading: Heading

  public init(position: GridPoint, heading: Heading) {
    self.position = position
    self.heading = heading
  }
}

public struct ShotSnapshot: Codable, Hashable, Sendable, Identifiable {
  public let id: UUID
  public let shooterID: UUID
  public let origin: GridPoint
  public let heading: Heading

  public init(id: UUID = UUID(), shooterID: UUID, origin: GridPoint, heading: Heading) {
    self.id = id
    self.shooterID = shooterID
    self.origin = origin
    self.heading = heading
  }
}

public struct DeathNotice: Codable, Hashable, Sendable {
  public let shotID: UUID
  public let killerID: UUID

  public init(shotID: UUID, killerID: UUID) {
    self.shotID = shotID
    self.killerID = killerID
  }
}

public enum NetworkMessage: Codable, Sendable {
  case player(PlayerSnapshot)
  case shot(ShotSnapshot)
  case death(DeathNotice)
}

public enum PlayerAction: Equatable, Sendable {
  case forward
  case backward
  case turnLeft
  case turnRight
  case turnAround
  case peekLeft
  case peekRight
}

public enum KeyboardCommand: Equatable, Sendable {
  case action(PlayerAction)
  case fire
  case stopPeeking
  case resetLocalGame
}

public enum KeyboardControls {
  public static func command(for characters: String) -> KeyboardCommand? {
    switch characters.lowercased() {
    case "a": .action(.turnAround)
    case "s": .action(.turnLeft)
    case "d": .action(.forward)
    case "f": .action(.turnRight)
    case " ": .action(.backward)
    case "[": .action(.peekLeft)
    case "]": .action(.peekRight)
    case "\\": .stopPeeking
    case "r": .fire
    case "n": .resetLocalGame
    default: nil
    }
  }
}

public struct MatchState: Sendable {
  public let arena: Arena
  public private(set) var player: PlayerSnapshot
  public private(set) var viewpoint: Viewpoint
  public private(set) var isPeeking = false
  public private(set) var shotsFired = 0
  private var firedShotIDs: Set<UUID> = []
  private var spawnIndex = 0

  public init(
    arena: Arena = .original,
    playerName: String,
    playerID: UUID = UUID(),
    startingAt start: GridPoint? = nil,
    heading: Heading? = nil
  ) {
    self.arena = arena
    let position = start ?? arena.openPoints().first ?? GridPoint(column: 0, row: 0)
    precondition(!arena.isWall(at: position))
    let startingHeading = heading ?? Self.firstOpenHeading(in: arena, from: position)
    player = PlayerSnapshot(id: playerID, name: playerName, position: position, heading: startingHeading)
    viewpoint = Viewpoint(position: position, heading: startingHeading)
  }

  @discardableResult
  public mutating func apply(_ action: PlayerAction) -> Bool {
    switch action {
    case .forward:
      return move(toward: player.heading)
    case .backward:
      return move(toward: player.heading.reversed)
    case .turnLeft:
      updatePlayer(heading: player.heading.turnedLeft)
    case .turnRight:
      updatePlayer(heading: player.heading.turnedRight)
    case .turnAround:
      updatePlayer(heading: player.heading.reversed)
    case .peekLeft:
      return beginPeek(toward: player.heading.turnedLeft)
    case .peekRight:
      return beginPeek(toward: player.heading.turnedRight)
    }
    return true
  }

  public mutating func stopPeeking() {
    isPeeking = false
    viewpoint = Viewpoint(position: player.position, heading: player.heading)
  }

  /// Firing costs one point immediately; a confirmed hit later refunds that point and awards ten.
  public mutating func fire() -> ShotSnapshot {
    shotsFired += 1
    updatePlayer(scoreDelta: -1)
    let shot = ShotSnapshot(shooterID: player.id, origin: player.position, heading: player.heading)
    firedShotIDs.insert(shot.id)
    return shot
  }

  /// Applies the historical delayed-shot outcome to this player when the packet reaches them.
  public mutating func receive(_ shot: ShotSnapshot) -> DeathNotice? {
    guard shot.shooterID != player.id,
      arena.hasLineOfSight(from: shot.origin, toward: player.position, facing: shot.heading)
    else { return nil }
    respawn()
    updatePlayer(scoreDelta: -5)
    return DeathNotice(shotID: shot.id, killerID: shot.shooterID)
  }

  /// The historical score change for a confirmed hit is +11 after the earlier -1 firing cost.
  @discardableResult
  public mutating func record(_ death: DeathNotice) -> Bool {
    guard death.killerID == player.id, firedShotIDs.remove(death.shotID) != nil else { return false }
    updatePlayer(scoreDelta: 11)
    return true
  }

  public func canSee(_ opponent: PlayerSnapshot) -> Bool {
    arena.hasLineOfSight(from: player.position, toward: opponent.position, facing: player.heading)
  }

  private mutating func move(toward heading: Heading) -> Bool {
    guard arena.canMove(from: player.position, toward: heading) else { return false }
    updatePlayer(position: heading.moved(from: player.position))
    return true
  }

  private mutating func beginPeek(toward side: Heading) -> Bool {
    guard arena.canMove(from: player.position, toward: side) else { return false }
    isPeeking = true
    viewpoint = Viewpoint(position: side.moved(from: player.position), heading: side)
    return true
  }

  private mutating func respawn() {
    let points = arena.openPoints()
    guard !points.isEmpty else { return }
    let previous = player.position
    var candidate = previous
    while candidate == previous && points.count > 1 {
      candidate = points[spawnIndex % points.count]
      spawnIndex += 1
    }
    updatePlayer(position: candidate, heading: Self.firstOpenHeading(in: arena, from: candidate))
  }

  private mutating func updatePlayer(
    position: GridPoint? = nil,
    heading: Heading? = nil,
    scoreDelta: Int = 0
  ) {
    player = PlayerSnapshot(
      id: player.id,
      name: player.name,
      position: position ?? player.position,
      heading: heading ?? player.heading,
      score: player.score + scoreDelta
    )
    if !isPeeking {
      viewpoint = Viewpoint(position: player.position, heading: player.heading)
    }
  }

  private static func firstOpenHeading(in arena: Arena, from point: GridPoint) -> Heading {
    Heading.allCases.first { arena.canMove(from: point, toward: $0) } ?? .east
  }
}
