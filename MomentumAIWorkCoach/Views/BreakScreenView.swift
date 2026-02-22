import SwiftUI

struct BreakScreenView: View {
    let breakDuration: Int
    let onBreakEnd: () -> Void

    @State private var timeRemaining: Int = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Theme.primaryTeal.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("Break")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
                    .frame(height: 48)

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .scaleEffect(breatheScale)
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 60, height: 60)
                        .scaleEffect(breatheScale * 0.9)
                }

                Spacer()
                    .frame(height: 48)

                Text("Step away from the screen.\nGet some water. Move a little.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                Button {
                    timer?.invalidate()
                    onBreakEnd()
                } label: {
                    Text("I'm back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.4), lineWidth: 1.5)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
                .sensoryFeedback(.impact(weight: .medium), trigger: timeRemaining)
            }
        }
        .onAppear {
            timeRemaining = breakDuration * 60
            startTimer()
            startBreathingAnimation()
        }
        .onDisappear { timer?.invalidate() }
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onBreakEnd()
            }
        }
    }

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breatheScale = 1.2
        }
    }
}
