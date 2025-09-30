import SwiftUI

struct ScratchParticleView: View {
    struct Particle: Identifiable {
        let id = UUID()
        let velocity: CGVector
    }

    private let lifetime: TimeInterval = 1.0
    private let particles: [Particle] = (0..<12).map { _ in
        let angle = Double.random(in: 0..<Double.pi * 2)
        let speed = CGFloat.random(in: 40...120)
        return Particle(velocity: CGVector(dx: cos(angle) * speed,
                                           dy: sin(angle) * speed))
    }
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            ZStack {
                ForEach(particles) { particle in
                    let progress = min(elapsed / lifetime, 1)
                    Circle()
                        .fill(Color.white.opacity(1 - progress))
                        .frame(width: 6, height: 6)
                        .offset(x: particle.velocity.dx * CGFloat(elapsed),
                                y: particle.velocity.dy * CGFloat(elapsed))
                }
            }
        }
        .onAppear { startDate = Date() }
    }
}

#Preview {
    ScratchParticleView()
}
