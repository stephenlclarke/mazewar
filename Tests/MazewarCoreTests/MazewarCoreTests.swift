import Foundation
import Testing

@testable import MazewarCore

@Test func generatedArenaIsDeterministic() {
  let first = ArenaGenerator.generate(columns: 8, rows: 6, seed: 42)
  let second = ArenaGenerator.generate(columns: 8, rows: 6, seed: 42)

  for row in 0..<first.rows {
    for column in 0..<first.columns {
      let point = GridPoint(column: column, row: row)
      for heading in Heading.allCases {
        #expect(
          first.hasWall(at: point, toward: heading) == second.hasWall(at: point, toward: heading))
      }
    }
  }
}

@Test func movementRespectsWallsAndFacing() {
  let arena = Arena(
    columns: 3,
    rows: 2,
    passages: [Passage(from: GridPoint(column: 0, row: 0), toward: .east)]
  )
  var match = MatchState(
    arena: arena, playerName: "Tester",
    playerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)

  let firstMove = match.apply(.forward)
  #expect(firstMove)
  #expect(match.player.position == GridPoint(column: 1, row: 0))
  let blockedMove = match.apply(.forward)
  #expect(!blockedMove)
  #expect(match.player.position == GridPoint(column: 1, row: 0))
  let turnedLeft = match.apply(.turnLeft)
  #expect(turnedLeft)
  #expect(match.player.heading == .north)
  let northBlocked = match.apply(.forward)
  #expect(!northBlocked)
}

@Test func lineOfSightRequiresAnOpenPathInTheFacingDirection() {
  let arena = Arena(
    columns: 3,
    rows: 2,
    passages: [
      Passage(from: GridPoint(column: 0, row: 0), toward: .east),
      Passage(from: GridPoint(column: 1, row: 0), toward: .east),
    ]
  )
  var match = MatchState(arena: arena, playerName: "Tester", playerID: UUID())
  let target = PlayerSnapshot(
    id: UUID(), name: "Target", position: GridPoint(column: 2, row: 0), heading: .west)

  #expect(match.canSee(target))
  let turnedRight = match.apply(.turnRight)
  #expect(turnedRight)
  #expect(!match.canSee(target))
}
