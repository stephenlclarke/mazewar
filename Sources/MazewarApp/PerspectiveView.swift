import MazewarCore
import SwiftUI

struct PerspectiveView: View {
  let arena: Arena
  let viewpoint: Viewpoint
  let opponents: [PlayerSnapshot]

  var body: some View {
    Canvas { context, size in
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
      drawMaze(in: &context, size: size)
      drawVisibleOpponents(in: &context, size: size)
    }
    .overlay(alignment: .topLeading) {
      Text("PERSPECTIVE")
        .font(.caption2.weight(.bold))
        .foregroundStyle(.cyan)
        .padding(8)
    }
    .accessibilityLabel("Mazewar first-person perspective")
  }

  private func drawMaze(in context: inout GraphicsContext, size: CGSize) {
    var position = viewpoint.position
    for depth in 0..<6 {
      let near = portal(depth: depth, in: size)
      let far = portal(depth: depth + 1, in: size)
      let next = viewpoint.heading.moved(from: position)
      if arena.isWall(at: next) {
        context.fill(Path(far), with: .color(.white))
        context.stroke(Path(far), with: .color(.cyan), lineWidth: 2)
        break
      }
      drawSideWall(
        arena.isWall(at: viewpoint.heading.turnedLeft.moved(from: position)),
        nearStart: CGPoint(x: near.minX, y: near.minY), nearEnd: CGPoint(x: near.minX, y: near.maxY),
        farStart: CGPoint(x: far.minX, y: far.minY), farEnd: CGPoint(x: far.minX, y: far.maxY),
        in: &context
      )
      drawSideWall(
        arena.isWall(at: viewpoint.heading.turnedRight.moved(from: position)),
        nearStart: CGPoint(x: near.maxX, y: near.minY), nearEnd: CGPoint(x: near.maxX, y: near.maxY),
        farStart: CGPoint(x: far.maxX, y: far.minY), farEnd: CGPoint(x: far.maxX, y: far.maxY),
        in: &context
      )
      context.stroke(Path(far), with: .color(.cyan.opacity(0.8)), lineWidth: 1)
      position = next
    }
  }

  private func drawVisibleOpponents(in context: inout GraphicsContext, size: CGSize) {
    for opponent in opponents {
      guard let depth = depth(of: opponent.position) else { continue }
      let frame = portal(depth: depth + 1, in: size)
      let rat = CGRect(x: frame.midX - frame.width * 0.12, y: frame.midY - frame.height * 0.22, width: frame.width * 0.24, height: frame.height * 0.44)
      context.fill(Path(ellipseIn: rat), with: .color(.orange))
    }
  }

  private func depth(of point: GridPoint) -> Int? {
    var cursor = viewpoint.position
    for depth in 0..<6 {
      cursor = viewpoint.heading.moved(from: cursor)
      guard !arena.isWall(at: cursor) else { return nil }
      if cursor == point { return depth }
    }
    return nil
  }

  private func portal(depth: Int, in size: CGSize) -> CGRect {
    let scale = pow(0.62, Double(depth))
    let width = size.width * scale
    let height = size.height * scale
    return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
  }

  private func drawSideWall(
    _ isWall: Bool,
    nearStart: CGPoint,
    nearEnd: CGPoint,
    farStart: CGPoint,
    farEnd: CGPoint,
    in context: inout GraphicsContext
  ) {
    guard isWall else { return }
    var path = Path()
    path.move(to: nearStart)
    path.addLine(to: nearEnd)
    path.addLine(to: farEnd)
    path.addLine(to: farStart)
    path.closeSubpath()
    context.fill(path, with: .color(.white.opacity(0.9)))
    context.stroke(path, with: .color(.cyan), lineWidth: 1)
  }
}
