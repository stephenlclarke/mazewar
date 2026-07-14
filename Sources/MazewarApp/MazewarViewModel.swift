import Foundation
import MazewarCore
import Observation

@MainActor
@Observable
final class MazewarViewModel {
  var match = MatchState(
    arena: ArenaGenerator.generate(seed: 0x4D_415A_4557_4152),
    playerName: Host.current().localizedName ?? "Player")
  var remotePlayers: [UUID: PlayerSnapshot] = [:]
  var statusMessage = "Ready to enter the maze."
  let peers = PeerSession()

  init() {
    peers.onSnapshot = { [weak self] snapshot in
      guard snapshot.id != self?.match.player.id else { return }
      self?.remotePlayers[snapshot.id] = snapshot
    }
  }

  var visiblePlayers: [PlayerSnapshot] {
    remotePlayers.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  func apply(_ action: PlayerAction) {
    let moved = match.apply(action)
    statusMessage = moved ? "\(description(for: action))." : "A wall blocks the way."
    broadcastState()
  }

  func fire() {
    match.fire()
    let targets = visiblePlayers.filter(match.canSee)
    if targets.isEmpty {
      statusMessage = "Shot \(match.shotsFired) fired into the maze."
    } else {
      statusMessage = "Target in sight: \(targets.map(\.name).joined(separator: ", "))."
    }
  }

  func newArena() {
    match = MatchState(
      arena: ArenaGenerator.generate(), playerName: match.player.name, playerID: match.player.id)
    remotePlayers.removeAll()
    statusMessage = "A new arena is ready."
    broadcastState()
  }

  func startNearbySession() {
    peers.start()
    statusMessage = "Looking for nearby Mazewar players."
    broadcastState()
  }

  private func broadcastState() {
    peers.send(match.player)
  }

  private func description(for action: PlayerAction) -> String {
    switch action {
    case .forward: "Moved forward"
    case .backward: "Moved backward"
    case .turnLeft: "Turned left"
    case .turnRight: "Turned right"
    case .turnAround: "Turned around"
    }
  }
}
