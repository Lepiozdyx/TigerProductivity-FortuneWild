import SwiftUI

private let activeNavColor = Color(red: 0.984, green: 0.004, blue: 0.004) // #FB0101
private let inactiveNavColor = Color(red: 79.0 / 255.0, green: 0.0, blue: 0.0) // #4F0000

/// Сообщает контейнеру, что оверлей Daily Zones должен перекрывать нижнюю панель.
struct DailyZonesDimsBottomBarKey: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Сообщает контейнеру, что оверлей Focus должен перекрывать нижнюю панель.
struct FocusDimsBottomBarKey: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

enum MainTab: CaseIterable {
    case quickHunt
    case dailyZones
    case focus
    case levels
    case stats

    var title: String {
        switch self {
        case .quickHunt: return "Quick Hunt"
        case .dailyZones: return "Daily Zones"
        case .focus: return "Focus"
        case .levels: return "Levels"
        case .stats: return "Stats"
        }
    }

    var icon: String {
        switch self {
        case .quickHunt: return "target"
        case .dailyZones: return "calendar"
        case .focus: return "flame"
        case .levels: return "trophy"
        case .stats: return "chart.bar"
        }
    }
}

struct MainTabContainerView: View {
    @State private var selectedTab: MainTab = .quickHunt
    @State private var hideBottomBarForQuickHunt = false
    @State private var dimBottomBarForDailyZones = false
    @State private var dimBottomBarForFocus = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("Quick Hunt")
                    .resizable()
                    .ignoresSafeArea()

                if (selectedTab == .dailyZones && dimBottomBarForDailyZones) || (selectedTab == .focus && dimBottomBarForFocus) {
                    BottomNavigationBar(selectedTab: $selectedTab, size: geo.size)
                        .padding(.bottom, 0)
                    selectedScreen
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onPreferenceChange(QuickHuntHidesBottomBarKey.self) { hideBottomBarForQuickHunt = $0 }
                        .onPreferenceChange(DailyZonesDimsBottomBarKey.self) { dimBottomBarForDailyZones = $0 }
                        .onPreferenceChange(FocusDimsBottomBarKey.self) { dimBottomBarForFocus = $0 }
                } else {
                    selectedScreen
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onPreferenceChange(QuickHuntHidesBottomBarKey.self) { hideBottomBarForQuickHunt = $0 }
                        .onPreferenceChange(DailyZonesDimsBottomBarKey.self) { dimBottomBarForDailyZones = $0 }
                        .onPreferenceChange(FocusDimsBottomBarKey.self) { dimBottomBarForFocus = $0 }

                    if !(selectedTab == .quickHunt && hideBottomBarForQuickHunt) {
                        BottomNavigationBar(selectedTab: $selectedTab, size: geo.size)
                            .padding(.bottom, 0)
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: selectedTab) { newTab in
                if newTab != .quickHunt {
                    hideBottomBarForQuickHunt = false
                }
                if newTab != .dailyZones {
                    dimBottomBarForDailyZones = false
                }
                if newTab != .focus {
                    dimBottomBarForFocus = false
                }
            }
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selectedTab {
        case .quickHunt:
            QuickHuntScreenView()
        case .dailyZones:
            DailyZonesScreenView()
        case .focus:
            FocusScreenView()
        case .levels:
            TigerLevelsScreenView()
        case .stats:
            StatsScreenView()
        }
    }
}

private struct BottomNavigationBar: View {
    @Binding var selectedTab: MainTab
    let size: CGSize

    private let baseWidth: CGFloat = 440
    private let baseHeight: CGFloat = 108

    var body: some View {
        // Adaptive scale for compact devices (SE) and large devices (Pro Max).
        // 440 is the CSS base width.
        let adaptiveScale = min(max(size.width / baseWidth, 0.72), 1.0)
        let panelWidth = baseWidth * adaptiveScale
        let panelHeight = baseHeight * adaptiveScale

        return GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                Image("ram")
                    .resizable()
                    .frame(width: panelWidth, height: panelHeight)

                navItem(.quickHunt, left: 45.45, width: 71.64, top: 32.31, scale: adaptiveScale)
                navItem(.dailyZones, left: 114.98, width: 93.92, top: 32.31, scale: adaptiveScale)
                navItem(.focus, left: 208.75, width: 60.56, top: 32.31, scale: adaptiveScale)
                navItem(.levels, left: 273.01, width: 62.7, top: 32.31, scale: adaptiveScale)
                navItem(.stats, left: 340.44, width: 57.45, top: 34.42, scale: adaptiveScale)
            }
            .frame(width: panelWidth, height: panelHeight, alignment: .topLeading)
            .position(x: size.width / 2, y: panelHeight / 2)
        }
        .frame(height: panelHeight)
    }

    private func navItem(_ tab: MainTab, left: CGFloat, width: CGFloat, top: CGFloat, scale: CGFloat) -> some View {
        let height: CGFloat = 58.98
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3.99 * scale) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18 * scale, weight: .regular))
                    .frame(width: 20 * scale, height: 20 * scale)
                Text(tab.title)
                    .font(.system(size: 12 * scale, weight: .medium))
                    .lineLimit(1)
                    .frame(height: 16 * scale)
            }
            .foregroundColor(isSelected ? activeNavColor : inactiveNavColor)
            .frame(width: width * scale, height: height * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(
            x: (left + width / 2) * scale,
            y: (top + height / 2) * scale
        )
    }
}

private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(activeNavColor)
            Spacer()
        }
    }
}

#Preview {
    MainTabContainerView()
        .environmentObject(FortuneWildStore())
}
