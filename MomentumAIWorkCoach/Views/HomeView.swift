import SwiftUI

struct HomeView: View {
    @Environment(StorageService.self) private var storage
    @State private var showSession: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            Theme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.primaryTeal.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(appeared ? 1 : 0.8)

                        Circle()
                            .fill(Theme.primaryTeal.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .scaleEffect(appeared ? 1 : 0.6)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.primaryTeal)
                            .scaleEffect(appeared ? 1 : 0.5)
                    }
                    .opacity(appeared ? 1 : 0)

                    Text("Momentum")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.primaryTeal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    Text("Your AI work session coach.")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textSecondary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                }

                Spacer()
                Spacer()

                VStack(spacing: 14) {
                    Button {
                        showSession = true
                    } label: {
                        Text("Start a Session")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.primaryTeal)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: showSession)

                    if storage.totalSessionCount > 0 {
                        Button {
                            NotificationCenter.default.post(name: .switchToWinsTab, object: nil)
                        } label: {
                            Text("\(storage.totalSessionCount) session\(storage.totalSessionCount == 1 ? "" : "s") · \(storage.totalCompletedItems) thing\(storage.totalCompletedItems == 1 ? "" : "s") done")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showSession) {
            SessionFlowView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

extension Notification.Name {
    static let switchToWinsTab = Notification.Name("switchToWinsTab")
}
