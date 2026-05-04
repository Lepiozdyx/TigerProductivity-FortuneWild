import AVFoundation
import AudioToolbox
import Foundation
import SwiftUI
import UIKit
import UserNotifications

enum TigerFeeling: String, Codable, CaseIterable, Identifiable {
    case nice
    case excited
    case tired
    case angry

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .nice: return "nice"
        case .excited: return "excited"
        case .tired: return "tired"
        case .angry: return "angry"
        }
    }

    var title: String {
        switch self {
        case .nice: return "Calm"
        case .excited: return "Happy"
        case .tired: return "Tired"
        case .angry: return "Energized"
        }
    }
}

enum DayZone: String, Codable, CaseIterable, Identifiable {
    case morning
    case day
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning Zone"
        case .day: return "Day Zone"
        case .evening: return "Evening Zone"
        }
    }

    var shortTitle: String {
        switch self {
        case .morning: return "Morning"
        case .day: return "Day"
        case .evening: return "Evening"
        }
    }
}

enum TigerAchievementID: String, Codable, CaseIterable, Identifiable {
    case firstBlood
    case weeklyHunter
    case zoneMaster
    case powerCycle
    case tigerEndurance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstBlood: return "First Blood"
        case .weeklyHunter: return "Weekly Hunter"
        case .zoneMaster: return "Zone Master"
        case .powerCycle: return "Power Cycle"
        case .tigerEndurance: return "Tiger Endurance"
        }
    }

    var detail: String {
        switch self {
        case .firstBlood: return "Complete your first quick hunt."
        case .weeklyHunter: return "Stay active for 7 days in a row."
        case .zoneMaster: return "Complete all 3 zones in a day."
        case .powerCycle: return "Finish 4 focus cycles in one session."
        case .tigerEndurance: return "Complete a 25 minute focus cycle."
        }
    }
}

struct QuickHuntTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var createdAt = Date()
    var completedAt: Date?
    var feeling: TigerFeeling?
    var nextAction: String = ""
}

struct ZoneTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var zone: DayZone
    var title: String
    var date = Date()
    var isCompleted = false
}

struct DailyZoneCompletion: Codable, Equatable, Hashable {
    var zone: DayZone
    var dayKey: String
}

struct DailyReflection: Identifiable, Codable, Equatable {
    var id = UUID()
    var dayKey: String
    var text: String
    var createdAt = Date()
}

struct FocusSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var completedAt = Date()
    var completedCycles: Int
    var focusMinutes: Int
}

struct FortuneWildState: Codable, Equatable {
    var points = 0
    var quickTasks: [QuickHuntTask] = []
    var zoneTasks: [ZoneTask] = []
    var completedZones: [DailyZoneCompletion] = []
    var dailyReflections: [DailyReflection] = []
    var focusSessions: [FocusSession] = []
    var unlockedAchievements: Set<TigerAchievementID> = []
}

struct TigerLevel: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let rangeTitle: String
    let minPoints: Int
    let maxPoints: Int?
    let privilege: String

    static let all: [TigerLevel] = [
        TigerLevel(id: 1, icon: "🐱", title: "Tiger Cub", rangeTitle: "0 - 50 XP", minPoints: 0, maxPoints: 50, privilege: "Basic animation, 1 tip a day"),
        TigerLevel(id: 2, icon: "🐯", title: "Young Hunter", rangeTitle: "51 - 200 XP", minPoints: 51, maxPoints: 200, privilege: "Daily zones, 3 tips a day"),
        TigerLevel(id: 3, icon: "🦁", title: "Ambush Master", rangeTitle: "201 - 500 XP", minPoints: 201, maxPoints: 500, privilege: "Timer customization, all 15 tips"),
        TigerLevel(id: 4, icon: "👑", title: "Jungle Ruler", rangeTitle: "501 - 1000 XP", minPoints: 501, maxPoints: 1000, privilege: "Stats export, dark theme"),
        TigerLevel(id: 5, icon: "🌟", title: "Legendary Tiger", rangeTitle: "1000+ XP", minPoints: 1000, maxPoints: nil, privilege: "Unique animation, certificate, priority support")
    ]
}

@MainActor
final class FortuneWildStore: ObservableObject {
    static let quickHuntDailyGoal = 5

    @Published var state: FortuneWildState {
        didSet { save() }
    }

    private let defaultsKey = "fortuneWild.state.v1"
    private let calendar = Calendar.current
    private let legacyDemoTaskTitles: Set<String> = [
        "Review morning emails",
        "Write project update",
        "Quick team sync"
    ]

    init() {
        if
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode(FortuneWildState.self, from: data)
        {
            state = decoded
        } else {
            state = FortuneWildState()
        }
        removeLegacyDemoTasks()
        refreshAchievements()
    }

    var currentLevel: TigerLevel {
        TigerLevel.all.last { state.points >= $0.minPoints } ?? TigerLevel.all[0]
    }

    var nextLevel: TigerLevel? {
        TigerLevel.all.first { $0.minPoints > state.points }
    }

    var progressToNextLevel: Double {
        guard let nextLevel else { return 1 }
        let current = currentLevel
        let range = max(nextLevel.minPoints - current.minPoints, 1)
        return min(max(Double(state.points - current.minPoints) / Double(range), 0), 1)
    }

    var todayQuickHunts: Int {
        state.quickTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }.count
    }

    var totalCompletedTasks: Int {
        state.quickTasks.filter(\.isCompleted).count + state.zoneTasks.filter(\.isCompleted).count
    }

    var totalFocusCycles: Int {
        state.focusSessions.reduce(0) { $0 + $1.completedCycles }
    }

    var averageFocusMinutes: Int {
        guard !state.focusSessions.isEmpty else { return 0 }
        let total = state.focusSessions.reduce(0) { $0 + $1.focusMinutes }
        return total / state.focusSessions.count
    }

    var favoriteZone: DayZone? {
        let counts = Dictionary(grouping: state.zoneTasks.filter(\.isCompleted), by: \.zone)
            .mapValues(\.count)
        guard !counts.isEmpty else { return nil }
        return DayZone.allCases.max { (counts[$0] ?? 0) < (counts[$1] ?? 0) }
    }

    func addQuickTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.quickTasks.insert(QuickHuntTask(title: trimmed), at: 0)
    }

    func completeQuickTask(id: UUID, feeling: TigerFeeling, nextAction: String) {
        guard let index = state.quickTasks.firstIndex(where: { $0.id == id }) else { return }
        if !state.quickTasks[index].isCompleted {
            state.points += 1
        }
        state.quickTasks[index].isCompleted = true
        state.quickTasks[index].completedAt = Date()
        state.quickTasks[index].feeling = feeling
        state.quickTasks[index].nextAction = String(nextAction.prefix(120))
        refreshAchievements()
    }

    func addZoneTask(zone: DayZone, title: String, date: Date = Date()) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.zoneTasks.append(ZoneTask(zone: zone, title: trimmed, date: date))
    }

    func toggleZoneTask(id: UUID) {
        guard let index = state.zoneTasks.firstIndex(where: { $0.id == id }) else { return }
        state.zoneTasks[index].isCompleted.toggle()
        refreshAchievements()
    }

    func deleteZoneTask(id: UUID) {
        state.zoneTasks.removeAll { $0.id == id }
        refreshAchievements()
    }

    func isZoneCompleted(_ zone: DayZone, date: Date = Date()) -> Bool {
        let key = Self.dayKey(for: date)
        return state.completedZones.contains { $0.zone == zone && $0.dayKey == key }
    }

    func toggleZoneCompletion(_ zone: DayZone, date: Date = Date()) {
        let completion = DailyZoneCompletion(zone: zone, dayKey: Self.dayKey(for: date))
        if let index = state.completedZones.firstIndex(of: completion) {
            state.completedZones.remove(at: index)
        } else {
            state.completedZones.append(completion)
        }
        refreshAchievements()
    }

    func zoneTasks(for zone: DayZone, date: Date = Date()) -> [ZoneTask] {
        let dayKey = Self.dayKey(for: date)
        return state.zoneTasks.filter { $0.zone == zone && Self.dayKey(for: $0.date) == dayKey }
    }

    var canFinishToday: Bool {
        DayZone.allCases.allSatisfy { zone in
            isZoneCompleted(zone) || !zoneTasks(for: zone).isEmpty
        }
    }

    var didFinishToday: Bool {
        state.dailyReflections.contains { $0.dayKey == Self.dayKey(for: Date()) }
    }

    func finishToday(reflection: String) {
        let dayKey = Self.dayKey(for: Date())
        if !didFinishToday {
            state.points += 2
        }
        if let index = state.dailyReflections.firstIndex(where: { $0.dayKey == dayKey }) {
            state.dailyReflections[index].text = reflection
        } else {
            state.dailyReflections.append(DailyReflection(dayKey: dayKey, text: reflection))
        }
        refreshAchievements()
    }

    func completeFocusSession(cycles: Int, focusMinutes: Int) {
        guard cycles > 0 else { return }
        state.focusSessions.append(FocusSession(completedCycles: cycles, focusMinutes: focusMinutes))
        state.points += cycles
        refreshAchievements()
    }

    func activityLastSevenDays() -> [Int] {
        lastSevenDayKeys().map { key in
            let quick = state.quickTasks.filter { $0.completedAt.map { Self.dayKey(for: $0) == key } ?? false }.count
            let zones = state.zoneTasks.filter { $0.isCompleted && Self.dayKey(for: $0.date) == key }.count
            let focus = state.focusSessions.filter { Self.dayKey(for: $0.completedAt) == key }.reduce(0) { $0 + $1.completedCycles }
            return quick + zones + focus
        }
    }

    func focusMinutesLastSevenDays() -> [Int] {
        lastSevenDayKeys().map { key in
            state.focusSessions.filter { Self.dayKey(for: $0.completedAt) == key }.reduce(0) { $0 + $1.focusMinutes }
        }
    }

    func moodBreakdown() -> [(feeling: TigerFeeling, count: Int, percent: Int)] {
        let counts = Dictionary(grouping: state.quickTasks.compactMap(\.feeling), by: { $0 }).mapValues(\.count)
        let total = max(counts.values.reduce(0, +), 1)
        return TigerFeeling.allCases.map { feeling in
            let count = counts[feeling] ?? 0
            return (feeling, count, Int((Double(count) / Double(total) * 100).rounded()))
        }
    }

    func zoneBreakdown() -> [(zone: DayZone, count: Int, progress: Double)] {
        let counts = Dictionary(grouping: state.zoneTasks.filter(\.isCompleted), by: \.zone).mapValues(\.count)
        let maxCount = max(counts.values.max() ?? 0, 1)
        return DayZone.allCases.map { zone in
            let count = counts[zone] ?? 0
            return (zone, count, Double(count) / Double(maxCount))
        }
    }

    private func refreshAchievements() {
        var unlocked = state.unlockedAchievements
        if state.quickTasks.contains(where: \.isCompleted) {
            unlocked.insert(.firstBlood)
        }
        if hasSevenDayStreak() {
            unlocked.insert(.weeklyHunter)
        }
        if DayZone.allCases.allSatisfy({ isZoneCompleted($0) }) {
            unlocked.insert(.zoneMaster)
        }
        if state.focusSessions.contains(where: { $0.completedCycles >= 4 }) {
            unlocked.insert(.powerCycle)
        }
        if state.focusSessions.contains(where: { $0.focusMinutes >= 25 }) {
            unlocked.insert(.tigerEndurance)
        }
        if unlocked != state.unlockedAchievements {
            state.unlockedAchievements = unlocked
        }
    }

    private func removeLegacyDemoTasks() {
        let filteredTasks = state.quickTasks.filter { task in
            !(legacyDemoTaskTitles.contains(task.title) && !task.isCompleted && task.nextAction.isEmpty)
        }
        guard filteredTasks != state.quickTasks else { return }
        state.quickTasks = filteredTasks
    }

    private func hasSevenDayStreak() -> Bool {
        lastSevenDayKeys().allSatisfy { key in
            state.quickTasks.contains { $0.completedAt.map { Self.dayKey(for: $0) == key } ?? false }
            || state.focusSessions.contains { Self.dayKey(for: $0.completedAt) == key }
            || state.dailyReflections.contains { $0.dayKey == key }
        }
    }

    private func lastSevenDayKeys() -> [String] {
        (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map(Self.dayKey)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

@MainActor
final class AppFeedback {
    static let shared = AppFeedback()

    private var buttonPlayer: AVAudioPlayer?
    private var roarPlayer: AVAudioPlayer?

    private init() {}

    func playButtonSound() {
        play(named: "button", player: &buttonPlayer)
    }

    func playRoarSound() {
        play(named: "rick", player: &roarPlayer)
    }

    func timerFinished() {
        playRoarSound()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    func postTimerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func play(named name: String, player: inout AVAudioPlayer?) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "m4a")
        else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }
}

struct ButtonSoundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                Task { @MainActor in
                    AppFeedback.shared.playButtonSound()
                }
            }
        )
    }
}

extension View {
    func fortuneWildButtonSounds() -> some View {
        modifier(ButtonSoundModifier())
    }
}

@MainActor
final class NotificationPermissionModel: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func request(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            Task { @MainActor in
                self.refresh()
                completion()
            }
        }
    }
}
