import MazewarCore
import SwiftUI

struct ArenaCanvas: View {
  let arena: Arena
  let player: PlayerSnapshot
  let opponents: [PlayerSnapshot]

  var body: some View {
    Canvas { context, size in
      let cell = min(size.width / CGFloat(arena.columns), size.height / CGFloat(arena.rows))
      let origin = CGPoint(
        x: (size.width - cell * CGFloat(arena.columns)) / 2,
        y: (size.height - cell * CGFloat(arena.rows)) / 2
      )
      for row in 0..<arena.rows {
        for column in 0..<arena.columns {
          let point = GridPoint(column: column, row: row)
          let rect = CGRect(
            x: origin.x + CGFloat(column) * cell,
            y: origin.y + CGFloat(row) * cell,
            width: cell,
            height: cell
          )
          context.fill(Path(rect), with: .color(arena.isWall(at: point) ? .white : .black))
        }
      }
      draw(player, color: .cyan, in: &context, cell: cell, origin: origin)
      for opponent in opponents {
        draw(opponent, color: .orange, in: &context, cell: cell, origin: origin)
      }
    }
    .background(.black, in: RoundedRectangle(cornerRadius: 8))
    .accessibilityLabel("Original Mazewar top-down maze map")
  }

  private func draw(
    _ player: PlayerSnapshot, color: Color, in context: inout GraphicsContext, cell: CGFloat,
    origin: CGPoint
  ) {
    let center = CGPoint(
      x: origin.x + (CGFloat(player.position.column) + 0.5) * cell,
      y: origin.y + (CGFloat(player.position.row) + 0.5) * cell
    )
    let radius = max(3, cell * 0.34)
    context.fill(
      Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
      with: .color(color)
    )
    let direction = player.heading.moved(from: GridPoint(column: 0, row: 0))
    var pointer = Path()
    pointer.move(to: CGPoint(x: center.x + CGFloat(direction.column) * radius, y: center.y + CGFloat(direction.row) * radius))
    pointer.addLine(to: CGPoint(x: center.x - CGFloat(direction.row) * radius * 0.55, y: center.y + CGFloat(direction.column) * radius * 0.55))
    pointer.addLine(to: CGPoint(x: center.x + CGFloat(direction.row) * radius * 0.55, y: center.y - CGFloat(direction.column) * radius * 0.55))
    pointer.closeSubpath()
    context.fill(pointer, with: .color(.black))
  }
}
