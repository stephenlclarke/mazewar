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
        Button("Move Forward") { model.apply(.forward) }
          .keyboardShortcut("w")
        Button("Move Backward") { model.apply(.backward) }
          .keyboardShortcut("s")
        Button("Turn Left") { model.apply(.turnLeft) }
          .keyboardShortcut("a")
        Button("Turn Right") { model.apply(.turnRight) }
          .keyboardShortcut("d")
        Divider()
        Button("Fire") { model.fire() }
          .keyboardShortcut(.space, modifiers: [])
        Button("New Arena") { model.newArena() }
          .keyboardShortcut("n")
      }
    }
  }
}
