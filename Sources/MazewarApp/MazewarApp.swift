import SwiftUI

@main
struct MazewarApp: App {
  @State private var model = MazewarViewModel()

  var body: some Scene {
    WindowGroup("Mazewar", id: "mazewar") {
      MazewarContentView(model: model)
        .onAppear { model.startKeyboardMonitoring() }
        .onDisappear { model.stopKeyboardMonitoring() }
    }
    .commands {
      CommandMenu("Mazewar") {
        Button("About Face") { model.apply(.turnAround) }
        Button("Turn Left") { model.apply(.turnLeft) }
        Button("Move Forward") { model.apply(.forward) }
        Button("Turn Right") { model.apply(.turnRight) }
        Button("Move Backward") { model.apply(.backward) }
        Divider()
        Button("Peek Left") { model.apply(.peekLeft) }
        Button("Peek Right") { model.apply(.peekRight) }
        Button("Stop Peeking") { model.stopPeeking() }
        Button("Fire") { model.fire() }
        Divider()
        Button("Reset Local Game") { model.resetLocalGame() }
      }
    }
  }
}
