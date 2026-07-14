import Foundation
import Testing

@testable import MazewarCore

@Test func retainedMazeBitmapMatchesTheOriginalDimensionsAndBoundary() {
  let arena = Arena.original

  #expect(arena.columns == 32)
  #expect(arena.rows == 16)
  #expect(arena.isWall(at: GridPoint(column: 0, row: 0)))
  #expect(arena.isWall(at: GridPoint(column: 31, row: 15)))
  #expect(!arena.isWall(at: GridPoint(column: 1, row: 1)))
  #expect(arena.canMove(from: GridPoint(column: 1, row: 1), toward: .south))
}

@Test func originalMovementKeysMoveOneOpenSquareAndKeepFacing() {
  let arena = Arena(columns: 4, rows: 3, walls: [GridPoint(column: 3, row: 1)])
  var match = MatchState(
    arena: arena, playerName: "Tester", playerID: UUID(), startingAt: GridPoint(column: 1, row: 1),
    heading: .east)

  let movedForward = match.apply(.forward)
  #expect(movedForward)
  #expect(match.player.position == GridPoint(column: 2, row: 1))
  let blockedForward = match.apply(.forward)
  #expect(!blockedForward)
  let turnedAround = match.apply(.turnAround)
  #expect(turnedAround)
  #expect(match.player.heading == .west)
  let blockedBackward = match.apply(.backward)
  #expect(!blockedBackward)
  let movedWest = match.apply(.forward)
  #expect(movedWest)
  #expect(match.player.position == GridPoint(column: 1, row: 1))
}

@Test func peekingMovesOnlyTheViewpointAroundAnOpenCorner() {
  let arena = Arena(columns: 4, rows: 4)
  var match = MatchState(
    arena: arena, playerName: "Tester", playerID: UUID(), startingAt: GridPoint(column: 1, row: 1),
    heading: .north)

  let peeked = match.apply(.peekLeft)
  #expect(peeked)
  #expect(match.isPeeking)
  #expect(match.player.position == GridPoint(column: 1, row: 1))
  #expect(match.viewpoint == Viewpoint(position: GridPoint(column: 0, row: 1), heading: .west))
  match.stopPeeking()
  #expect(!match.isPeeking)
  #expect(match.viewpoint == Viewpoint(position: match.player.position, heading: .north))
}

@Test func aConfirmedDelayedShotUsesTheHistoricalScoreChanges() {
  let arena = Arena(columns: 5, rows: 3)
  var shooter = MatchState(
    arena: arena, playerName: "Shooter", playerID: UUID(), startingAt: GridPoint(column: 1, row: 1),
    heading: .east)
  var target = MatchState(
    arena: arena, playerName: "Target", playerID: UUID(), startingAt: GridPoint(column: 3, row: 1),
    heading: .west)

  let shot = shooter.fire()
  #expect(shooter.player.score == -1)
  let death = target.receive(shot)
  #expect(death == DeathNotice(shotID: shot.id, killerID: shooter.player.id))
  #expect(target.player.score == -5)
  #expect(target.player.position != GridPoint(column: 3, row: 1))
  let recordedDeath = shooter.record(death!)
  #expect(recordedDeath)
  #expect(shooter.player.score == 10)
}

@Test func wallsBlockSightAndADeathCannotBeClaimedTwice() {
  let arena = Arena(columns: 5, rows: 3, walls: [GridPoint(column: 2, row: 1)])
  var shooter = MatchState(
    arena: arena, playerName: "Shooter", playerID: UUID(), startingAt: GridPoint(column: 1, row: 1),
    heading: .east)
  var target = MatchState(
    arena: arena, playerName: "Target", playerID: UUID(), startingAt: GridPoint(column: 3, row: 1),
    heading: .west)

  let missedShot = shooter.fire()
  #expect(target.receive(missedShot) == nil)

  let notice = DeathNotice(shotID: missedShot.id, killerID: shooter.player.id)
  let firstRecord = shooter.record(notice)
  let secondRecord = shooter.record(notice)
  #expect(firstRecord)
  #expect(!secondRecord)
}
