import SwiftUI

struct FortuneWildRootView: View {
    @StateObject private var store = FortuneWildStore()
    @StateObject private var notificationModel = NotificationPermissionModel()
    @AppStorage("fortuneWild.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("fortuneWild.hasRequestedNotificationPermission") private var hasRequestedNotificationPermission = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            } else {
                MainTabContainerView()
                    .environmentObject(store)
                    .onAppear(perform: requestNotificationPermissionIfNeeded)
            }
        }
        .fortuneWildButtonSounds()
    }

    private func requestNotificationPermissionIfNeeded() {
        guard !hasRequestedNotificationPermission else { return }
        notificationModel.request {
            hasRequestedNotificationPermission = true
        }
    }
}

#Preview {
    FortuneWildRootView()
}
