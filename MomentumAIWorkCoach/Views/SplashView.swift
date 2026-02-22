import SwiftUI

struct SplashView: View {
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 10

    var body: some View {
        ZStack {
            Theme.primaryTeal
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Momentum")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.white.opacity(dotOpacities[index]))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
                titleOffset = 0
            }
            animateDots()
        }
    }

    private func animateDots() {
        func pulse(index: Int) {
            withAnimation(.easeInOut(duration: 0.4).delay(Double(index) * 0.2)) {
                dotOpacities[index] = 1.0
            }
            withAnimation(.easeInOut(duration: 0.4).delay(Double(index) * 0.2 + 0.4)) {
                dotOpacities[index] = 0.3
            }
        }

        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            for i in 0..<3 { pulse(index: i) }
        }
        for i in 0..<3 { pulse(index: i) }
    }
}
