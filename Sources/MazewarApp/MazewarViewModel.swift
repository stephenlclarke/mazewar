import Foundation
import MazewarCore
import Observation

@MainActor
@Observable
final class MazewarViewModel {
  var match = MatchState(arena: .original, playerName: Host.current().localizedName ?? "Player")
  var remotePlayers: [UUID: PlayerSnapshot] = [:]
  var statusMessage = "Ready to enter the original Alto maze."
  let peers = PeerSession()

  init() {
    peers.onMessage = { [weak self] message in
      self?.receive(message)
    }
  }

  var visiblePlayers: [PlayerSnapshot] {
    remotePlayers.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  func apply(_ action: PlayerAction) {
    let changed = match.apply(action)
    statusMessage = changed ? "\(description(for: action))." : "A wall blocks the way."
    broadcastState()
  }

  func stopPeeking() {
    match.stopPeeking()
    statusMessage = "Looking forward again."
  }

  func fire() {
    let shot = match.fire()
    peers.send(.shot(shot))
    statusMessage = "Shot fired: -1 point now; a hit is resolved after one second."
    broadcastState()
  }

  func resetLocalGame() {
    match = MatchState(
      arena: .original, playerName: match.player.name, playerID: match.player.id)
    remotePlayers.removeAll()
    statusMessage = "The original maze and scorecard have been reset."
    broadcastState()
  }

  func startNearbySession() {
    peers.start()
    statusMessage = "Looking for nearby Mazewar players."
    broadcastState()
  }

  private func receive(_ message: NetworkMessage) {
    switch message {
    case let .player(snapshot):
      guard snapshot.id != match.player.id else { return }
      remotePlayers[snapshot.id] = snapshot
    case let .shot(shot):
      guard shot.shooterID != match.player.id else { return }
      statusMessage = "Incoming shot — move or return fire before it arrives."
      Task { [weak self] in
        try? await Task.sleep(for: .seconds(1))
        self?.resolve(shot)
      }
    case let .death(death):
      guard match.record(death) else { return }
      statusMessage = "Confirmed hit: +10 points."
      broadcastState()
    }
  }

  private func resolve(_ shot: ShotSnapshot) {
    guard let death = match.receive(shot) else { return }
    peers.send(.death(death))
    statusMessage = "You were hit: -5 points and a new position."
    broadcastState()
  }

  private func broadcastState() {
    peers.send(.player(match.player))
  }

  private func description(for action: PlayerAction) -> String {
    switch action {
    case .forward: "Moved forward one square"
    case .backward: "Moved backward one square"
    case .turnLeft: "Turned left"
    case .turnRight: "Turned right"
    case .turnAround: "Turned about face"
    case .peekLeft: "Peeking left around the corner"
    case .peekRight: "Peeking right around the corner"
    }
  }
}
