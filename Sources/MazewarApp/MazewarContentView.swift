import MazewarCore
import SwiftUI

struct MazewarContentView: View {
  @Bindable var model: MazewarViewModel

  var body: some View {
    VStack(spacing: 12) {
      PerspectiveView(
        arena: model.match.arena,
        viewpoint: model.match.viewpoint,
        opponents: model.visiblePlayers
      )
      .frame(minWidth: 680, idealWidth: 800, minHeight: 260, idealHeight: 340)

      HStack(alignment: .top, spacing: 16) {
        ArenaCanvas(
          arena: model.match.arena, player: model.match.player, opponents: model.visiblePlayers
        )
        .frame(width: 500, height: 250)

        GroupBox("Original controls") {
          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 7) {
            control("A", "about face", .turnAround)
            control("S", "turn left", .turnLeft)
            control("D", "forward one cell", .forward)
            control("F", "turn right", .turnRight)
            control("Space", "backward one cell", .backward)
          }
          Divider().padding(.vertical, 5)
          HStack {
            Button("Peek Left") { model.apply(.peekLeft) }
            Button("Peek Right") { model.apply(.peekRight) }
          }
          Button("Stop Peeking") { model.stopPeeking() }
            .disabled(!model.match.isPeeking)
          Button("Fire (-1)", systemImage: "scope") { model.fire() }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 190)
      }

      GroupBox("Scorecard") {
        HStack {
          Label("\(model.match.player.name) (you)", systemImage: "person.fill")
          Spacer()
          Text("\(model.match.player.score)").monospacedDigit()
        }
        ForEach(model.visiblePlayers) { player in
          HStack {
            Text(player.name)
              .foregroundStyle(model.match.canSee(player) ? .orange : .primary)
            Spacer()
            Text("\(player.score)").monospacedDigit()
          }
        }
        Divider()
        HStack {
          Text(model.statusMessage).foregroundStyle(.secondary)
          Spacer()
          Button(model.peers.isRunning ? "Nearby Session Active" : "Start Nearby Session") {
            model.startNearbySession()
          }
          .disabled(model.peers.isRunning)
          Button("Reset Local Game") { model.resetLocalGame() }
        }
      }
    }
    .padding()
    .navigationTitle("Mazewar")
  }

  @ViewBuilder
  private func control(_ key: String, _ label: String, _ action: PlayerAction) -> some View {
    Text(key).font(.system(.body, design: .monospaced).weight(.semibold))
    Button(label) { model.apply(action) }
      .buttonStyle(.plain)
  }
}
