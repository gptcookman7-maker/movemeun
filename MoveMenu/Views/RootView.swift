import SwiftUI
import UIKit

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDay = DayKey.make(Date())

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日菜单", systemImage: "fork.knife") }
            ActivityView()
                .tabItem { Label("运动", systemImage: "figure.run") }
            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .sheet(isPresented: Binding(get: { !store.profile.completed }, set: { _ in })) {
            ProfileEditor(initial: store.profile, onboarding: true)
                .interactiveDismissDisabled()
        }
        .alert("提示", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("知道了") { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshDay()
        }
    }

    private func refreshDay() {
        let nextDay = DayKey.make(Date())
        if currentDay != nextDay {
            if DayKey.make(store.selectedDate) == currentDay { store.selectedDate = Date() }
            currentDay = nextDay
        }
    }
}

#Preview("已建立档案") {
    RootView().environment(AppStore.preview).environment(HealthService())
}
