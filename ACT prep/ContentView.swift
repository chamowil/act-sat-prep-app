//
//  ContentView.swift
//  ACT prep
//

import SwiftUI

enum AppTab: Hashable {
    case home, learn, practice, progress, settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var settings = UserSettings.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView(selectedTab: $selectedTab)
            }
            Tab("Tutorials", systemImage: "book.fill", value: AppTab.learn) {
                LearnView()
            }
            Tab("Practice", systemImage: "pencil.and.list.clipboard", value: AppTab.practice) {
                PracticeView()
            }
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.progress) {
                ProgressDashboardView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        // Uses a sidebar on iPad and Mac, a tab bar on iPhone.
        .tabViewStyle(.sidebarAdaptable)
        .fullScreenCover(isPresented: Binding(
            get: { !settings.hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
