import SwiftUI

private enum FocusState {
    case one
    case two
    case three
}

struct FocusScreenView: View {
    @EnvironmentObject private var store: FortuneWildStore
    private let ringRotationOffset: Double = -10
    @State private var focusState: FocusState = .one
    @State private var remainingSeconds = 25 * 60
    @State private var completedCycles = 0
    @State private var isRestPhase = false
    @State private var isPaused = false
    @State private var currentTip = "Stretch like a tiger: arch your back and reach your paws."

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let restTips = [
        "Stretch like a tiger: arch your back and reach your paws.",
        "Take 3 deep breaths: inhale, hold, exhale.",
        "Look into the distance: tigers scan the horizon.",
        "Drink water: a tiger drinks after the hunt.",
        "Close your eyes for 30 seconds: rest in the shade.",
        "Check your posture: a tiger keeps the back straight.",
        "Smile: even tigers enjoy a successful hunt.",
        "Blink quickly: refresh your eyes.",
        "Tell yourself: I can handle this.",
        "Shake your paws: release the tension.",
        "Listen to silence: a tiger hears every rustle.",
        "Stretch your neck: turn slowly and gently.",
        "Pause: a tiger waits before striking.",
        "Thank yourself: a tiger values the work.",
        "Prepare for the next leap: stay ready."
    ]

    var body: some View {
        GeometryReader { geo in
            let xScale = geo.size.width / 440
            let navHeight: CGFloat = 108 * xScale
            let availableHeight = max(geo.size.height - navHeight, 1)
            let yScale = availableHeight / 863

            ZStack(alignment: .topLeading) {
                focusScreenBase(scaleX: xScale, scaleY: yScale)
                    .frame(width: geo.size.width, height: availableHeight, alignment: .top)

                switch focusState {
                case .one:
                    focusStateOneContent(scaleX: xScale, scaleY: yScale)
                case .two:
                    focusStateTwoContent(scaleX: xScale, scaleY: yScale)
                case .three:
                    ZStack(alignment: .topLeading) {
                        focusStateTwoContent(scaleX: xScale, scaleY: yScale)
                        focusStateThreeContent(scaleX: xScale, scaleY: yScale)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .preference(key: FocusDimsBottomBarKey.self, value: focusState == .three)
            .onReceive(ticker) { _ in
                tickFocusTimer()
            }
        }
    }

    private func focusScreenBase(scaleX: CGFloat, scaleY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * scaleX,
                bottomTrailingRadius: 32 * scaleX,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(red: 1, green: 0, blue: 0), Color(red: 0.714, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 440 * scaleX, height: 186 * scaleY)
            .position(x: 220 * scaleX, y: 93 * scaleY)

            VStack(alignment: .leading, spacing: 8 * scaleY) {
                Text("Deep Focus")
                    .font(.custom("Outfit-Medium", size: 30 * scaleX))
                    .foregroundColor(.white)
                Text("25 min focus / 5 min rest")
                    .font(.system(size: 14 * scaleX))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .frame(width: 392.45 * scaleX, alignment: .leading)
            .position(x: 220 * scaleX, y: 125 * scaleY)

            HStack(spacing: 11.99 * scaleX) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 99)
                        .fill(index < completedCycles ? Color(red: 0.463, green: 0, blue: 0) : Color(red: 0.976, green: 0.004, blue: 0.004))
                        .frame(width: 48 * scaleX, height: 11.99 * scaleY)
                }
            }
            .position(x: (24 + 196.225) * scaleX, y: (203 + 5.995) * scaleY)

            Text("Cycle \(min(completedCycles + 1, 4))/4")
                .font(.system(size: 16 * scaleX))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                .frame(width: 392.45 * scaleX)
                .position(x: (18 + 196.225) * scaleX, y: (234 + 12) * scaleY)
        }
    }

    private func focusStateOneContent(scaleX: CGFloat, scaleY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Image("cute-cartoon-tiger-character-set--inspired-by-fort 5")
                .resizable()
                .scaledToFit()
                .frame(width: 216.59 * scaleX, height: 186.55 * scaleY)
                .rotationEffect(.degrees(14.96))
                .position(x: (85 + 108.295) * scaleX, y: (258 + 93.275) * scaleY)

            focusRing(scaleX: scaleX, scaleY: scaleY, timeText: timeText, modeText: "FOCUS TIME")
                .position(x: (76 + 143.995) * scaleX, y: (462 + 143.995) * scaleY)

            Button(action: startFocusSession) {
                HStack(spacing: 7.99 * scaleX) {
                    Image(systemName: "play")
                        .font(.system(size: 20 * scaleX, weight: .medium))
                        .foregroundColor(Color(red: 0.31, green: 0, blue: 0))
                    Text("Start Hunt")
                        .font(.system(size: 18 * scaleX, weight: .medium))
                        .foregroundColor(Color(red: 0.31, green: 0, blue: 0))
                }
                .frame(width: 180.29 * scaleX, height: 59.98 * scaleY)
                .background(Color(red: 0.98, green: 0.004, blue: 0.004))
                .clipShape(RoundedRectangle(cornerRadius: 16 * scaleX, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 8 * scaleX, x: 0, y: 4 * scaleY)
            }
            .buttonStyle(.plain)
            .position(x: (25 + 196.225) * scaleX, y: (772 + 29.99) * scaleY)
        }
    }

    private func focusStateTwoContent(scaleX: CGFloat, scaleY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Image("cute-cartoon-tiger-character-set--inspired-by-fort 4-2")
                .resizable()
                .scaledToFit()
                .frame(width: 255 * scaleX, height: 159 * scaleY)
                .position(x: (93 + 127.5) * scaleX, y: (275 + 79.5) * scaleY)

            focusRing(scaleX: scaleX, scaleY: scaleY, timeText: timeText, modeText: isRestPhase ? "REST TIME" : "FOCUS TIME")
                .position(x: (76 + 143.995) * scaleX, y: (447 + 143.995) * scaleY)

            if isRestPhase {
                Text(currentTip)
                    .font(.system(size: 15 * scaleX))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    .multilineTextAlignment(.center)
                    .frame(width: 320 * scaleX)
                    .position(x: (60 + 160) * scaleX, y: (705 + 18) * scaleY)
            }

            Button(action: { isPaused.toggle() }) {
                HStack(spacing: 7.99 * scaleX) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 20 * scaleX, weight: .medium))
                        .foregroundColor(Color(red: 199.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0))
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.system(size: 18 * scaleX, weight: .medium))
                        .foregroundColor(Color(red: 199.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0))
                }
                .frame(width: 128 * scaleX, height: 52 * scaleY)
                .background(Color(red: 152.0 / 255.0, green: 1.0, blue: 248.0 / 255.0))
                .clipShape(RoundedRectangle(cornerRadius: 16 * scaleX, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10 * scaleX, x: 0, y: 4 * scaleY)
            }
            .buttonStyle(.plain)
            .position(x: (18 + 196.225) * scaleX, y: (742 + 29.99) * scaleY)

            HStack(spacing: 11.99 * scaleX) {
                Button {
                    remainingSeconds += 5 * 60
                } label: {
                    smallActionButton(
                    icon: "plus",
                    title: "+5 min",
                    width: 121.16 * scaleX,
                    height: 47.98 * scaleY
                    )
                }
                .buttonStyle(.plain)
                Button {
                    finishFocusSession()
                } label: {
                    smallActionButton(
                    icon: "Icon-5",
                    title: "End Early",
                    width: 140.34 * scaleX,
                    height: 47.98 * scaleY,
                    useAssetIcon: true
                    )
                }
                .buttonStyle(.plain)
            }
            .position(x: (24 + 196.225) * scaleX, y: (815 + 23.99) * scaleY)
        }
    }

    private func focusStateThreeContent(scaleX: CGFloat, scaleY: CGFloat) -> some View {
        let s = min(scaleX, scaleY)
        return ZStack(alignment: .topLeading) {
            Color(red: 82.0 / 255.0, green: 0, blue: 0, opacity: 0.52)
                .ignoresSafeArea()
                .onTapGesture { resetFocusSession() }

            Image("cute-cartoon-tiger-character-set--inspired-by-fort 6-2")
                .resizable()
                .scaledToFit()
                .frame(width: 351 * scaleX, height: 331 * scaleY)
                .position(x: (24 + 175.5) * scaleX, y: (85 + 165.5) * scaleY)

            Image("Group 551")
                .resizable()
                .scaledToFit()
                .frame(width: 392 * scaleX, height: 382 * scaleY)
                .position(x: (24.22 + 196) * scaleX, y: (287 + 191) * scaleY)

            Image("game-visual-effects-set--fortune-tiger-style--glow 4")
                .resizable()
                .scaledToFit()
                .frame(width: 142 * scaleX, height: 114 * scaleY)
                .rotationEffect(.degrees(150.93))
                .position(x: (146 + 71) * scaleX, y: (449 + 57) * scaleY)

            Image("game-visual-effects-set--fortune-tiger-style--glow 5")
                .resizable()
                .scaledToFit()
                .frame(width: 146.97 * scaleX, height: 118.6 * scaleY)
                .rotationEffect(.degrees(-15))
                .position(x: (122.995 + 73.485) * scaleX, y: (449 + 59.3) * scaleY)

            Text("\(completedCycles) cycles completed")
                .font(.system(size: 18 * s, weight: .medium))
                .foregroundColor(Color(red: 79.0 / 255.0, green: 0.0, blue: 0.0))
                .frame(width: 163 * scaleX, height: 28 * scaleY)
                .position(x: (138 + 81.5) * scaleX, y: (600 + 14) * scaleY)
        }
    }

    private func focusRing(scaleX: CGFloat, scaleY: CGFloat, timeText: String, modeText: String) -> some View {
        let ringSize: CGFloat = 256
        let ringStroke: CGFloat = 12.8

        return ZStack {
            Circle()
                .stroke(Color(red: 0.596, green: 1.0, blue: 0.973), lineWidth: ringStroke * min(scaleX, scaleY))
                .rotationEffect(.degrees(ringRotationOffset))
                .frame(width: ringSize * scaleX, height: ringSize * scaleY)

            // Cross segments centered exactly at top/right/bottom/left.
            segmentArc(from: 0.975, to: 1.0, scaleX: scaleX, scaleY: scaleY)
            segmentArc(from: 0.0, to: 0.075, scaleX: scaleX, scaleY: scaleY)
            segmentArc(from: 0.225, to: 0.325, scaleX: scaleX, scaleY: scaleY)
            segmentArc(from: 0.475, to: 0.575, scaleX: scaleX, scaleY: scaleY)
            segmentArc(from: 0.725, to: 0.825, scaleX: scaleX, scaleY: scaleY)

            VStack(spacing: 8 * scaleY) {
                Text(timeText)
                    .font(.system(size: 60 * scaleX, weight: .regular))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text(modeText)
                    .font(.system(size: 14 * scaleX))
                    .tracking(0.7 * scaleX)
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }
        }
        .frame(width: ringSize * scaleX, height: ringSize * scaleY)
    }

    private func smallActionButton(icon: String, title: String, width: CGFloat, height: CGFloat, useAssetIcon: Bool = false) -> some View {
        return HStack(spacing: 7.99) {
            if useAssetIcon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .frame(width: 16, height: 16)
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
        }
        .frame(width: width, height: height)
        .background(Color(red: 254.0 / 255.0, green: 237.0 / 255.0, blue: 218.0 / 255.0))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func segmentArc(from: CGFloat, to: CGFloat, scaleX: CGFloat, scaleY: CGFloat) -> some View {
        let ringSize: CGFloat = 256
        let ringStroke: CGFloat = 12.8

        return Circle()
            .trim(from: from, to: to)
            .stroke(
                Color(red: 0.976, green: 0.004, blue: 0.004),
                style: StrokeStyle(lineWidth: ringStroke * min(scaleX, scaleY), lineCap: .round)
            )
            .rotationEffect(.degrees(-90 + ringRotationOffset))
            .frame(width: ringSize * scaleX, height: ringSize * scaleY)
    }

    private var timeText: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private func startFocusSession() {
        completedCycles = 0
        isRestPhase = false
        isPaused = false
        remainingSeconds = 25 * 60
        focusState = .two
    }

    private func tickFocusTimer() {
        guard focusState == .two, !isPaused else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        guard remainingSeconds == 0 else { return }

        AppFeedback.shared.timerFinished()
        if isRestPhase {
            isRestPhase = false
            remainingSeconds = 25 * 60
            AppFeedback.shared.postTimerNotification(title: "Back to the Hunt", body: "Rest is done. Start the next tiger focus cycle.")
        } else {
            completedCycles += 1
            if completedCycles >= 4 {
                store.completeFocusSession(cycles: completedCycles, focusMinutes: completedCycles * 25)
                AppFeedback.shared.postTimerNotification(title: "Session Complete", body: "4 cycles completed. You are a real tiger!")
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    focusState = .three
                }
            } else {
                isRestPhase = true
                currentTip = restTips.randomElement() ?? currentTip
                remainingSeconds = 5 * 60
                AppFeedback.shared.postTimerNotification(title: "Rest Like a Tiger", body: currentTip)
            }
        }
    }

    private func finishFocusSession() {
        if completedCycles > 0 {
            store.completeFocusSession(cycles: completedCycles, focusMinutes: completedCycles * 25)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                focusState = .three
            }
        } else {
            resetFocusSession()
        }
    }

    private func resetFocusSession() {
        focusState = .one
        completedCycles = 0
        isRestPhase = false
        isPaused = false
        remainingSeconds = 25 * 60
    }
}

#Preview {
    FocusScreenView()
        .environmentObject(FortuneWildStore())
}
