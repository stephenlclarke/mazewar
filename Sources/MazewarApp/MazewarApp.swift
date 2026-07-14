import SwiftUI

@main
struct MazewarApp: App {
  @State private var model = MazewarViewModel()

  var body: some Scene {
    WindowGroup("Mazewar", id: "mazewar") {
      MazewarContentView(model: model)
    }
    .commands {
      CommandMenu("Mazewar") {
        Button("About Face") { model.apply(.turnAround) }
          .keyboardShortcut("a")
        Button("Turn Left") { model.apply(.turnLeft) }
          .keyboardShortcut("s")
        Button("Move Forward") { model.apply(.forward) }
          .keyboardShortcut("d")
        Button("Turn Right") { model.apply(.turnRight) }
          .keyboardShortcut("f")
        Button("Move Backward") { model.apply(.backward) }
          .keyboardShortcut(.space, modifiers: [])
        Divider()
        Button("Peek Left") { model.apply(.peekLeft) }
          .keyboardShortcut("[")
        Button("Peek Right") { model.apply(.peekRight) }
          .keyboardShortcut("]")
        Button("Stop Peeking") { model.stopPeeking() }
          .keyboardShortcut("\\")
        Button("Fire") { model.fire() }
          .keyboardShortcut("r")
        Divider()
        Button("Reset Local Game") { model.resetLocalGame() }
          .keyboardShortcut("n")
      }
    }
  }
}
