import SwiftUI

private let quickHuntActive = Color(red: 245.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0) // #F50101
private let ambushRed = Color(red: 242.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0) // #F20101
private let creamBg = Color(red: 1.0, green: 248.0 / 255.0, blue: 225.0 / 255.0) // #FFF8E1
private let plusYellow = Color(red: 1.0, green: 227.0 / 255.0, blue: 139.0 / 255.0) // #FFE38B

/// Сообщает `MainTabContainerView`, что нижнюю панель нужно скрыть (состояние 2 Quick Hunt).
struct QuickHuntHidesBottomBarKey: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private enum QuickHuntPhase {
    case one
    case two(ambushTask: QuickHuntTask)
    case three(ambushTask: QuickHuntTask)
    case four
}

private typealias AmbushFeeling = TigerFeeling

/// Кольцо таймера: 8 сегментов по 45°, фаза как в CSS — верхний градиентный сегмент по центру в 12:00.
/// Сначала слой #FFE0B2, сверху чередующиеся дуги с градиентом #FFC107 → #FF8F00 (скруглённые концы).
private struct EightSegmentTimerRing: View {
    let diameter: CGFloat
    let lineWidth: CGFloat

    private static let base = Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0) // #FFE0B2
    private static let gradA = Color(red: 1.0, green: 193.0 / 255.0, blue: 7.0 / 255.0) // #FFC107
    private static let gradB = Color(red: 1.0, green: 143.0 / 255.0, blue: 0.0) // #FF8F00

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = max(min(size.width, size.height) / 2 - lineWidth / 2, 1)
            let gap: CGFloat = 0.01
            let step = (2 * CGFloat.pi) / 8
            // Сдвиг на −3π/8: как rotate(−90deg) + выравнивание в CSS — центр верхнего
            // градиентного сегмента (нечётный индекс) в 12 часов, кольцо «ровно».
            let angleOrigin = -CGFloat.pi / 2 - 3 * CGFloat.pi / 8
            let baseStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter)
            let overlayStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)

            for i in stride(from: 0, to: 8, by: 2) {
                let start = CGFloat(i) * step + angleOrigin + gap
                let end = CGFloat(i + 1) * step + angleOrigin - gap
                var path = Path()
                path.addArc(
                    center: center,
                    radius: r,
                    startAngle: .radians(Double(start)),
                    endAngle: .radians(Double(end)),
                    clockwise: false
                )
                context.stroke(path, with: .color(Self.base), style: baseStyle)
            }

            for i in stride(from: 1, to: 8, by: 2) {
                let start = CGFloat(i) * step + angleOrigin + gap
                let end = CGFloat(i + 1) * step + angleOrigin - gap
                var path = Path()
                path.addArc(
                    center: center,
                    radius: r,
                    startAngle: .radians(Double(start)),
                    endAngle: .radians(Double(end)),
                    clockwise: false
                )
                let p0 = CGPoint(x: center.x + r * cos(start), y: center.y + r * sin(start))
                let p1 = CGPoint(x: center.x + r * cos(end), y: center.y + r * sin(end))
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Self.gradA, Self.gradB]),
                        startPoint: p0,
                        endPoint: p1
                    ),
                    style: overlayStyle
                )
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

struct QuickHuntScreenView: View {
    @EnvironmentObject private var store: FortuneWildStore
    @State private var huntInput = ""
    @State private var phase: QuickHuntPhase = .one
    @State private var ambushMinutes: Int = 7
    @State private var selectedFeeling: AmbushFeeling = .excited
    @State private var nextActionInput = ""
    @State private var ambushRemainingSeconds = 7 * 60
    @State private var isAmbushRunning = false
    @State private var showRewardOverlay = false

    private let ambushTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hidesBottomBar: Bool {
        if case .two = phase { return true }
        if case .three = phase { return true }
        if case .four = phase { return true }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            Group {
                switch phase {
                case .one:
                    quickHuntPhaseOne(geo: geo)
                case .two(let task):
                    quickHuntPhaseTwo(geo: geo, ambushTask: task)
                case .three(let task):
                    quickHuntPhaseTwo(geo: geo, ambushTask: task)
                case .four:
                    quickHuntPhaseFour(geo: geo)
                }
            }
            .preference(key: QuickHuntHidesBottomBarKey.self, value: hidesBottomBar)
            .onReceive(ambushTicker) { _ in
                tickAmbushTimer()
            }
        }
    }

    // MARK: - Phase 1

    private func quickHuntPhaseOne(geo: GeometryProxy) -> some View {
        let xScale = geo.size.width / 440
        let bottomReserve: CGFloat = 108
        let headerVerticalScale = min(1, max((geo.size.height - bottomReserve) / 598, 0.82))
        let headerH = 186 * xScale * headerVerticalScale
        let scale = xScale
        let offsetX: CGFloat = 0
        let offsetY: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * xScale,
                bottomTrailingRadius: 32 * xScale,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(red: 1, green: 0, blue: 0), Color(red: 0.714, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 10 * xScale, x: 0, y: 4 * xScale)
            .shadow(color: .black.opacity(0.1), radius: 4 * xScale, x: 0, y: -2 * xScale)
            .frame(width: 440 * xScale, height: headerH)
            .position(x: offsetX + 220 * xScale, y: offsetY + headerH / 2)

            headerTitleBlock(scale: scale, headerH: headerH, offsetX: offsetX, offsetY: offsetY)

            huntInputRowPhaseOne(scale: scale)
                .position(x: offsetX + 220 * scale, y: offsetY + 251 * scale)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12 * scale) {
                    ForEach(store.state.quickTasks) { task in
                        if task.isCompleted {
                            completedTaskRowPhaseFour(task.title, scale: scale)
                        } else {
                            taskRowPhaseOne(task.title, scale: scale) {
                                startAmbush(for: task)
                            }
                        }
                    }
                }
                .frame(width: 392.45 * scale)
            }
            .frame(width: 392.45 * scale, height: max(geo.size.height - 315 * scale - bottomReserve, 120 * scale))
            .offset(x: offsetX + 24 * scale, y: offsetY + 303 * scale)
        }
        .ignoresSafeArea()
    }

    private func quickHuntPhaseFour(geo: GeometryProxy) -> some View {
        let xScale = geo.size.width / 440
        let bottomReserve: CGFloat = 108
        let headerVerticalScale = min(1, max((geo.size.height - bottomReserve) / 598, 0.82))
        let headerH = 186 * xScale * headerVerticalScale
        let scale = xScale
        let offsetX: CGFloat = 0
        let offsetY: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * xScale,
                bottomTrailingRadius: 32 * xScale,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(red: 1, green: 0, blue: 0), Color(red: 0.714, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 10 * xScale, x: 0, y: 4 * xScale)
            .shadow(color: .black.opacity(0.1), radius: 4 * xScale, x: 0, y: -2 * xScale)
            .frame(width: 440 * xScale, height: headerH)
            .position(x: offsetX + 220 * xScale, y: offsetY + headerH / 2)

            headerTitleBlock(scale: scale, headerH: headerH, offsetX: offsetX, offsetY: offsetY)

            huntInputRowPhaseOne(scale: scale)
                .position(x: offsetX + 220 * scale, y: offsetY + 251 * scale)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12 * scale) {
                    ForEach(store.state.quickTasks) { task in
                        if task.isCompleted {
                            completedTaskRowPhaseFour(task.title, scale: scale)
                        } else {
                            taskRowPhaseOne(task.title, scale: scale) {
                                startAmbush(for: task)
                            }
                        }
                    }
                }
                .frame(width: 392.45 * scale)
            }
            .frame(width: 392.45 * scale, height: max(geo.size.height - 315 * scale - bottomReserve, 120 * scale))
            .offset(x: offsetX + 24 * scale, y: offsetY + 303 * scale)

            if showRewardOverlay {
                rewardOverlayPhaseFour(geo: geo)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showRewardOverlay = true
            }
        }
    }

    private func headerTitleBlock(scale: CGFloat, headerH: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 11.99 * scale) {
            Text("Quick Hunt")
                .font(.custom("Outfit-Medium", size: 30 * scale))
                .foregroundColor(.white)

            HStack(spacing: 11.99 * scale) {
                let trackH = 11.99 * scale
                let trackW = 316.79 * scale
                let pillRadius = trackH / 2
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: trackW, height: trackH)
                    RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                        .fill(Color.white)
                        .frame(width: max(1, trackW * min(CGFloat(store.todayQuickHunts) / CGFloat(FortuneWildStore.quickHuntDailyGoal), 1)), height: trackH)
                }

                Text("\(store.todayQuickHunts)/\(FortuneWildStore.quickHuntDailyGoal) hunts")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            }
        }
        .frame(width: 392.45 * scale, alignment: .leading)
        .position(
            x: offsetX + (24 + 196.225) * scale,
            y: offsetY + headerH * (126.995 / 186)
        )
    }

    private func huntInputRowPhaseOne(scale: CGFloat) -> some View {
        HStack(spacing: 11.99 * scale) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .fill(Color(red: 1.0, green: 248.0 / 255.0, blue: 225.0 / 255.0))

                TextField("", text: $huntInput, prompt: Text("What will you hunt today?")
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459)))
                    .font(.system(size: 16 * scale))
                    .padding(.vertical, 12 * scale)
                    .padding(.horizontal, 16 * scale)
            }
            .frame(width: 300.47 * scale, height: 47.99 * scale)

            Button {
                store.addQuickTask(title: huntInput)
                huntInput = ""
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24 * scale, weight: .medium))
                    .foregroundColor(quickHuntActive)
                    .frame(width: 47.99 * scale, height: 47.99 * scale)
                    .background(plusYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
            }
            .buttonStyle(.plain)
        }
        .padding(15.9956 * scale)
        .frame(width: 392.45 * scale, height: 79.98 * scale)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
    }

    private func taskRowPhaseOne(_ text: String, scale: CGFloat, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 11.99 * scale) {
            Image(systemName: "circle")
                .font(.system(size: 24 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))

            Text(text)
                .font(.system(size: 16 * scale))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "clock")
                .font(.system(size: 20 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
        }
        .padding(15.9956 * scale)
        .frame(width: 392.45 * scale, height: 55.99 * scale)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
        .onTapGesture(perform: onTap)
    }

    // MARK: - Phase 2 (CSS AppContent + modal)

    private func quickHuntPhaseTwo(geo: GeometryProxy, ambushTask: QuickHuntTask) -> some View {
        let s = geo.size.width / 440
        let headerH = 115.99 * s

        return ZStack {
            creamBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                phaseTwoFrostHeader(scale: s, headerH: headerH)
                    .frame(height: headerH)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 24 * s) {
                    huntInputRowPhaseTwo(scale: s)

                    VStack(spacing: 11.99 * s) {
                        ForEach(store.state.quickTasks) { task in
                            if task.isCompleted {
                                completedTaskRowPhaseFour(task.title, scale: s)
                            } else {
                                taskRowPhaseTwo(task.title, scale: s) {
                                    startAmbush(for: task)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 23.9978 * s)
                .padding(.top, 23.9978 * s)

                Spacer(minLength: 0)
            }

            ambushModalOverlay(geo: geo, task: ambushTask, scale: s)
                .transition(.scale.combined(with: .opacity))
        }
        .ignoresSafeArea()
    }

    /// CSS: height 115.99, rgba(255,255,255,~0), тени, скругление снизу 32. Текст белый — добавляем лёгкий красный слой под материалом.
    private func phaseTwoFrostHeader(scale: CGFloat, headerH: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * scale,
                bottomTrailingRadius: 32 * scale,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(red: 1, green: 0, blue: 0).opacity(0.92), Color(red: 0.714, green: 0, blue: 0).opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * scale,
                bottomTrailingRadius: 32 * scale,
                topTrailingRadius: 0
            )
            .fill(Color.white.opacity(0.04))
            .shadow(color: .black.opacity(0.1), radius: 10 * scale, x: 0, y: 4 * scale)
            .shadow(color: .black.opacity(0.1), radius: 4 * scale, x: 0, y: -2 * scale)

            VStack(alignment: .leading, spacing: 11.99 * scale) {
                Text("Quick Hunt")
                    .font(.custom("Outfit-Medium", size: 30 * scale))
                    .foregroundColor(.white)

                HStack(spacing: 11.99 * scale) {
                    let trackH = 11.99 * scale
                    let trackW = 316.79 * scale
                    let pillRadius = trackH / 2
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: trackW, height: trackH)
                        RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                            .fill(Color.white)
                            .frame(width: max(1, trackW * min(CGFloat(store.todayQuickHunts) / CGFloat(FortuneWildStore.quickHuntDailyGoal), 1)), height: trackH)
                    }

                    Text("\(store.todayQuickHunts)/\(FortuneWildStore.quickHuntDailyGoal) hunts")
                        .font(.system(size: 14 * scale, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                }
            }
            .padding(.horizontal, 23.9978 * scale)
            .padding(.bottom, 23.9978 * scale)
        }
    }

    private func huntInputRowPhaseTwo(scale: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 11.99 * scale) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .fill(creamBg)

                TextField("", text: $huntInput, prompt: Text("What will you hunt today?")
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459)))
                    .font(.system(size: 16 * scale))
                    .padding(.vertical, 12 * scale)
                    .padding(.horizontal, 16 * scale)
            }
            .frame(width: 300.47 * scale, height: 47.99 * scale)

            Button {
                store.addQuickTask(title: huntInput)
                huntInput = ""
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24 * scale, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 47.99 * scale, height: 47.99 * scale)
                    .background(Color.white.opacity(0.00001))
                    .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
            }
            .buttonStyle(.plain)
        }
        .padding(15.9956 * scale)
        .frame(width: 392.45 * scale, height: 79.98 * scale, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
    }

    private func taskRowPhaseTwo(_ text: String, scale: CGFloat, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 11.99 * scale) {
            Image(systemName: "circle")
                .font(.system(size: 24 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))

            Text(text)
                .font(.system(size: 16 * scale))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "clock")
                .font(.system(size: 20 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
        }
        .padding(15.9956 * scale)
        .frame(width: 392.45 * scale, height: 55.99 * scale)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
        .onTapGesture(perform: onTap)
    }

    // MARK: - Ambush modal (CSS absolute layout inside 408.45×844.38)

    private func ambushModalOverlay(geo: GeometryProxy, task: QuickHuntTask, scale: CGFloat) -> some View {
        let isResultState: Bool = {
            if case .three = phase { return true }
            return false
        }()
        let designCardW: CGFloat = isResultState ? 408.0 : 408.45
        let designCardH: CGFloat = isResultState ? 822.0 : 844.38
        let cardW = min(designCardW * scale, geo.size.width - 16 * scale)
        let cardH = min(designCardH * scale, geo.size.height - 16 * scale)
        let layoutScale = min(1, cardH / (designCardH * scale))

        return ZStack {
            ZStack {
                // Тоновая подложка из CSS.
                Color(red: 82.0 / 255.0, green: 0, blue: 0, opacity: 0.80)
                // Лёгкая белая дымка, чтобы вуаль читалась и на красной шапке прошлого экрана.
                Color.white.opacity(0.80)
            }
            .ignoresSafeArea()
            .onTapGesture {
                isAmbushRunning = false
                phase = .one
            }

            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if isResultState {
                        ambushResultModalContent(task: task, scale: scale, layoutScale: layoutScale)
                    } else {
                        ambushTimerModalContent(task: task, scale: scale, layoutScale: layoutScale)
                    }
                }
                .frame(width: cardW, height: designCardH * scale * layoutScale)
            }
            .frame(width: cardW, height: cardH)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                    .stroke(Color.red, lineWidth: 6 * scale)
            )
            .shadow(color: .black.opacity(0.25), radius: 25 * scale, x: 0, y: 12 * scale)
        }
    }

    private func ambushTimerModalContent(task: QuickHuntTask, scale: CGFloat, layoutScale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: 408.45 * scale * layoutScale, height: 844.38 * scale * layoutScale)

            modalHeaderRow(taskTitle: task.title, scale: scale, layoutScale: layoutScale)
                .frame(width: 360.46 * scale * layoutScale, height: 51.99 * scale * layoutScale)
                .offset(x: 24 * scale * layoutScale, y: 24 * scale * layoutScale)

            Image("tiger")
                .resizable()
                .scaledToFit()
                .frame(width: 315 * scale * layoutScale, height: 248 * scale * layoutScale)
                .offset(x: 38 * scale * layoutScale, y: 104.19 * scale * layoutScale)

            timerModalBlock(scale: scale, layoutScale: layoutScale)
                .frame(width: 360.46 * scale * layoutScale, height: 360.46 * scale * layoutScale)
                .offset(x: 24 * scale * layoutScale, y: 315.97 * scale * layoutScale)

            HStack(spacing: 7.99 * scale * layoutScale) {
                durationChip(title: "5 min", width: 71.98 * scale * layoutScale, selected: ambushMinutes == 5, scale: scale * layoutScale) { setAmbushMinutes(5) }
                durationChip(title: "7 min", width: 70.89 * scale * layoutScale, selected: ambushMinutes == 7, scale: scale * layoutScale) { setAmbushMinutes(7) }
                durationChip(title: "10 min", width: 79.2 * scale * layoutScale, selected: ambushMinutes == 10, scale: scale * layoutScale) { setAmbushMinutes(10) }
            }
            .frame(width: 360.46 * scale * layoutScale, height: 39.98 * scale * layoutScale)
            .offset(x: 24 * scale * layoutScale, y: 700.43 * scale * layoutScale)

            Button {
                startAmbushTimer()
            } label: {
                HStack(spacing: 7.99 * scale * layoutScale) {
                    Image("Icon-4")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20 * scale * layoutScale, height: 20 * scale * layoutScale)
                    Text(isAmbushRunning ? "Hunting..." : "Start Hunt")
                        .font(.system(size: 16 * scale * layoutScale, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 360.46 * scale * layoutScale, height: 55.98 * scale * layoutScale)
            }
            .buttonStyle(.plain)
            .background(ambushRed)
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale * layoutScale, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10 * scale * layoutScale, x: 0, y: 4 * scale * layoutScale)
            .offset(x: 24 * scale * layoutScale, y: 764.4 * scale * layoutScale)
        }
    }

    private func ambushResultModalContent(task: QuickHuntTask, scale: CGFloat, layoutScale: CGFloat) -> some View {
        let s = scale * layoutScale
        return ZStack(alignment: .topLeading) {
            Color.clear.frame(width: 408 * s, height: 822 * s)

            modalHeaderRow(taskTitle: task.title, scale: scale, layoutScale: layoutScale)
                .frame(width: 360.46 * s, height: 51.99 * s)
                .offset(x: 24 * s, y: 24 * s)

            Image("cute-cartoon-tiger-character-set--inspired-by-fort 6")
                .resizable()
                .scaledToFit()
                .frame(width: 304 * s, height: 287 * s)
                .offset(x: 40 * s, y: 87.19 * s)

            VStack(spacing: -18 * s) {
                Text("You struck!")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                Text("Get some rest!")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            .font(.system(size: 40 * s, weight: .black))
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .frame(width: 285 * s, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .offset(x: 64 * s, y: 393.19 * s)

            Text("How do you feel?")
                .font(.system(size: 16 * s, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .offset(x: 144 * s, y: 485.19 * s)

            moodIcon(feeling: .nice, x: 32, y: 528.19, s: s)
            moodIcon(feeling: .excited, x: 120, y: 528.19, s: s)
            moodIcon(feeling: .tired, x: 211, y: 528.19, s: s)
            moodIcon(feeling: .angry, x: 293, y: 528.19, s: s)

            Text("What will you do next?")
                .font(.system(size: 16 * s, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .offset(x: 123 * s, y: 627.19 * s)

            TextField("", text: $nextActionInput, prompt: Text("I will...")
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459)))
                .font(.system(size: 16 * s, weight: .regular))
                .padding(.horizontal, 16 * s)
                .frame(width: 360.46 * s, height: 47.99 * s)
                .background(creamBg)
                .clipShape(RoundedRectangle(cornerRadius: 20 * s, style: .continuous))
                .offset(x: 24 * s, y: 662.19 * s)

            Button {
                store.completeQuickTask(id: task.id, feeling: selectedFeeling, nextAction: nextActionInput)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showRewardOverlay = true
                    phase = .four
                }
            } label: {
                Text("Go next!")
                    .font(.system(size: 16 * s, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 360.46 * s, height: 55.98 * s)
            }
            .buttonStyle(.plain)
            .background(ambushRed)
            .clipShape(RoundedRectangle(cornerRadius: 16 * s, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10 * s, x: 0, y: 4 * s)
            .offset(x: 24 * s, y: 738.19 * s)
        }
    }

    private func completedTaskRowPhaseFour(_ text: String, scale: CGFloat) -> some View {
        HStack(spacing: 11.99 * scale) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))

            Text(text)
                .font(.system(size: 16 * scale))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                .strikethrough(true, color: Color(red: 0.459, green: 0.459, blue: 0.459))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15.9956 * scale)
        .frame(width: 392.45 * scale, height: 55.99 * scale)
        .background(Color(red: 203.0 / 255.0, green: 203.0 / 255.0, blue: 203.0 / 255.0))
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
    }

    private func rewardOverlayPhaseFour(geo: GeometryProxy) -> some View {
        let overlayW: CGFloat = 440.44
        let overlayH: CGFloat = 956
        let s = min(geo.size.width / overlayW, geo.size.height / overlayH)
        return ZStack {
            Color(red: 82.0 / 255.0, green: 0, blue: 0, opacity: 0.52)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showRewardOverlay = false
                        phase = .one
                    }
                }

            ZStack(alignment: .topLeading) {
                Image("Group 546")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 392 * s, height: 382 * s)
                    .position(
                        x: ((overlayW - 392) / 2 + 392 / 2) * s,
                        y: ((overlayH - 382) / 2 + 382 / 2) * s
                    )
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showRewardOverlay = false
                            phase = .one
                        }
                    }
            }
            .frame(width: overlayW * s, height: overlayH * s, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func moodIcon(feeling: AmbushFeeling, x: CGFloat, y: CGFloat, s: CGFloat) -> some View {
        Button {
            selectedFeeling = feeling
        } label: {
            ZStack {
                if selectedFeeling == feeling {
                    Image("set-of-premium-gold-ui-frames--chinese-imperial-st 6")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 89 * s, height: 89 * s)
                }
                Image(feeling.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 83 * s, height: 66 * s)
            }
            .frame(width: 89 * s, height: 89 * s)
        }
        .buttonStyle(.plain)
        .offset(x: (x - 3) * s, y: (y - 11.5) * s)
    }

    private func modalHeaderRow(taskTitle: String, scale: CGFloat, layoutScale: CGFloat) -> some View {
        let s = scale * layoutScale
        return HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3.99 * s) {
                Text("Ambush Mode")
                    .font(.custom("Outfit-Medium", size: 20 * s))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text(taskTitle)
                    .font(.system(size: 14 * s, weight: .regular))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isAmbushRunning = false
                phase = .one
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12 * s, weight: .medium))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    .frame(width: 20 * s, height: 20 * s)
            }
            .buttonStyle(.plain)
        }
    }

    private func timerModalBlock(scale: CGFloat, layoutScale: CGFloat) -> some View {
        let s = scale * layoutScale
        let box = 360.46 * s
        // CSS: кольцо с inset 10% → диаметр 80% от блока 360.46; толщина обводки 21.6274px.
        let ringDiameter = box * 0.8
        let ringLine: CGFloat = 21.6274 * s

        return ZStack(alignment: .topLeading) {
            EightSegmentTimerRing(diameter: ringDiameter, lineWidth: ringLine)
                .position(x: box / 2, y: box / 2)

            Text(ambushTimeText)
                .font(.system(size: 48 * s, weight: .bold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .position(x: box / 2, y: box / 2)
        }
        .frame(width: box, height: box)
    }

    private func durationChip(title: String, width: CGFloat, selected: Bool, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundColor(selected ? .white : Color(red: 0.102, green: 0.102, blue: 0.102))
                .frame(width: width, height: 39.98 * scale)
                .background(selected ? ambushRed : Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0))
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
                .shadow(color: selected ? .black.opacity(0.1) : .clear, radius: 10 * scale, x: 0, y: 4 * scale)
        }
        .buttonStyle(.plain)
    }

    private var ambushTimeText: String {
        let minutes = ambushRemainingSeconds / 60
        let seconds = ambushRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startAmbush(for task: QuickHuntTask) {
        selectedFeeling = .excited
        nextActionInput = ""
        showRewardOverlay = false
        isAmbushRunning = false
        ambushRemainingSeconds = ambushMinutes * 60
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            phase = .two(ambushTask: task)
        }
    }

    private func setAmbushMinutes(_ minutes: Int) {
        guard !isAmbushRunning else { return }
        ambushMinutes = minutes
        ambushRemainingSeconds = minutes * 60
    }

    private func startAmbushTimer() {
        ambushRemainingSeconds = ambushMinutes * 60
        isAmbushRunning = true
    }

    private func tickAmbushTimer() {
        guard isAmbushRunning else { return }
        guard case .two(let task) = phase else {
            isAmbushRunning = false
            return
        }
        if ambushRemainingSeconds > 0 {
            ambushRemainingSeconds -= 1
        }
        if ambushRemainingSeconds == 0 {
            isAmbushRunning = false
            AppFeedback.shared.timerFinished()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                phase = .three(ambushTask: task)
            }
        }
    }
}

#Preview {
    QuickHuntScreenView()
        .environmentObject(FortuneWildStore())
}
