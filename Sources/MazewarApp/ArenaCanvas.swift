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
      drawWalls(in: &context, cell: cell, origin: origin)
      draw(player, color: .accentColor, in: &context, cell: cell, origin: origin)
      for opponent in opponents {
        draw(opponent, color: .orange, in: &context, cell: cell, origin: origin)
      }
    }
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityLabel("Mazewar arena")
  }

  private func drawWalls(in context: inout GraphicsContext, cell: CGFloat, origin: CGPoint) {
    for row in 0..<arena.rows {
      for column in 0..<arena.columns {
        let point = GridPoint(column: column, row: row)
        let x = origin.x + CGFloat(column) * cell
        let y = origin.y + CGFloat(row) * cell
        var path = Path()
        if arena.hasWall(at: point, toward: .north) { horizontal(&path, x: x, y: y, cell: cell) }
        if arena.hasWall(at: point, toward: .west) { vertical(&path, x: x, y: y, cell: cell) }
        if row == arena.rows - 1 { horizontal(&path, x: x, y: y + cell, cell: cell) }
        if column == arena.columns - 1 { vertical(&path, x: x + cell, y: y, cell: cell) }
        context.stroke(path, with: .foreground, lineWidth: max(1, cell * 0.06))
      }
    }
  }

  private func draw(
    _ player: PlayerSnapshot, color: Color, in context: inout GraphicsContext, cell: CGFloat,
    origin: CGPoint
  ) {
    let center = CGPoint(
      x: origin.x + (CGFloat(player.position.column) + 0.5) * cell,
      y: origin.y + (CGFloat(player.position.row) + 0.5) * cell
    )
    let radius = max(4, cell * 0.3)
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
      with: .color(color))
    let tip = player.heading.moved(from: GridPoint(column: 0, row: 0))
    let direction = CGPoint(x: CGFloat(tip.column), y: CGFloat(tip.row))
    var pointer = Path()
    pointer.move(
      to: CGPoint(x: center.x + direction.x * radius, y: center.y + direction.y * radius))
    pointer.addLine(
      to: CGPoint(
        x: center.x - direction.y * radius * 0.55, y: center.y + direction.x * radius * 0.55))
    pointer.addLine(
      to: CGPoint(
        x: center.x + direction.y * radius * 0.55, y: center.y - direction.x * radius * 0.55))
    pointer.closeSubpath()
    context.fill(pointer, with: .color(.white))
  }

  private func horizontal(_ path: inout Path, x: CGFloat, y: CGFloat, cell: CGFloat) {
    path.move(to: CGPoint(x: x, y: y))
    path.addLine(to: CGPoint(x: x + cell, y: y))
  }

  private func vertical(_ path: inout Path, x: CGFloat, y: CGFloat, cell: CGFloat) {
    path.move(to: CGPoint(x: x, y: y))
    path.addLine(to: CGPoint(x: x, y: y + cell))
  }
}
