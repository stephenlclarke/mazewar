import MazewarCore
import SwiftUI

struct MazewarContentView: View {
  @Bindable var model: MazewarViewModel

  var body: some View {
    NavigationSplitView {
      List {
        Section("Nearby players") {
          if model.peers.connectedPeerNames.isEmpty {
            Text("No players connected")
              .foregroundStyle(.secondary)
          } else {
            ForEach(model.peers.connectedPeerNames, id: \.self, content: Text.init)
          }
        }
        Section("Scoreboard") {
          Text("\(model.match.player.name) (you) · \(model.match.player.score)")
          ForEach(model.visiblePlayers) { player in
            Text("\(player.name) · \(player.score)")
          }
        }
      }
      .navigationTitle("Mazewar")
      .safeAreaInset(edge: .bottom) {
        Button(model.peers.isRunning ? "Nearby Session Active" : "Start Nearby Session") {
          model.startNearbySession()
        }
        .disabled(model.peers.isRunning)
        .buttonStyle(.borderedProminent)
        .padding()
      }
    } detail: {
      VStack(spacing: 12) {
        ArenaCanvas(
          arena: model.match.arena, player: model.match.player, opponents: model.visiblePlayers
        )
        .frame(minWidth: 640, minHeight: 430)
        .padding(.horizontal)
        Text(model.statusMessage)
          .foregroundStyle(.secondary)
        HStack {
          Button("Turn Left", systemImage: "arrow.counterclockwise") { model.apply(.turnLeft) }
          Button("Forward", systemImage: "arrow.up") { model.apply(.forward) }
          Button("Turn Right", systemImage: "arrow.clockwise") { model.apply(.turnRight) }
          Button("Back", systemImage: "arrow.down") { model.apply(.backward) }
          Divider()
          Button("Fire", systemImage: "scope") { model.fire() }
          Button("New Arena", systemImage: "dice") { model.newArena() }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .padding(.bottom)
      }
      .onKeyPress { press in
        switch press.characters.lowercased() {
        case "w": model.apply(.forward)
        case "s": model.apply(.backward)
        case "a": model.apply(.turnLeft)
        case "d": model.apply(.turnRight)
        case " ": model.fire()
        default: return .ignored
        }
        return .handled
      }
    }
  }
}
