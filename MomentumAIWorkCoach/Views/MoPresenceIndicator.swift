import SwiftUI

struct MoPresenceIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.primaryTeal)
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == index ? 1.3 : 0.8)
                    .opacity(phase == index ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.4), value: phase)
            }
        }
        .onAppear { startPulsing() }
    }

    private func startPulsing() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            phase = (phase + 1) % 3
        }
    }
}
