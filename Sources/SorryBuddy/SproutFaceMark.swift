import SwiftUI

struct SproutFaceMark: View {
    var isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let lineWidth = max(size * 0.06, 2)
            let color = isActive ? Color.primary : Color.secondary

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: size * 0.50, y: size * 0.38))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.28, y: size * 0.18),
                        control: CGPoint(x: size * 0.34, y: size * 0.22)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.50, y: size * 0.38),
                        control: CGPoint(x: size * 0.35, y: size * 0.04)
                    )

                    path.move(to: CGPoint(x: size * 0.50, y: size * 0.38))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.72, y: size * 0.18),
                        control: CGPoint(x: size * 0.66, y: size * 0.22)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.50, y: size * 0.38),
                        control: CGPoint(x: size * 0.65, y: size * 0.04)
                    )

                    path.move(to: CGPoint(x: size * 0.50, y: size * 0.38))
                    path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.58))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(color)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .position(x: size * 0.36, y: size * 0.70)

                Circle()
                    .fill(color)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .position(x: size * 0.64, y: size * 0.70)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
