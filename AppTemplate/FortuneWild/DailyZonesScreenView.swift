import SwiftUI

fileprivate struct ZoneData: Identifiable {
    let zone: DayZone
    let title: String
    let time: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let plusColors: [Color]

    var id: DayZone { zone }
}

private enum DailyZonesState {
    case one
    case two
    case three
}

struct DailyZonesScreenView: View {
    @EnvironmentObject private var store: FortuneWildStore
    @State private var state: DailyZonesState = .one
    @State private var reflectionInput = ""
    @State private var morningInput = ""
    @State private var dayInput = ""
    @State private var eveningInput = ""

    private let zones: [ZoneData] = [
        ZoneData(
            zone: .morning,
            title: "Morning Zone",
            time: "06:00-12:00",
            subtitle: "Tiger hunts at dawn. Do important tasks.",
            icon: "sun.max",
            colors: [Color(red: 0.98, green: 0.78, blue: 0.86), Color(red: 0.96, green: 0.57, blue: 0.58)],
            plusColors: [Color(red: 1.0, green: 0.757, blue: 0.027), Color(red: 1.0, green: 0.757, blue: 0.027).opacity(0.87)]
        ),
        ZoneData(
            zone: .day,
            title: "Day Zone",
            time: "12:00-18:00",
            subtitle: "Patrol and handle smaller tasks.",
            icon: "bolt",
            colors: [Color(red: 1.0, green: 0.66, blue: 0.2), Color(red: 1.0, green: 0.56, blue: 0.0)],
            plusColors: [Color(red: 1.0, green: 0.56, blue: 0.0), Color(red: 1.0, green: 0.56, blue: 0.0).opacity(0.87)]
        ),
        ZoneData(
            zone: .evening,
            title: "Evening Zone",
            time: "18:00-24:00",
            subtitle: "Rest and recover.",
            icon: "moon",
            colors: [Color(red: 0.06, green: 0.11, blue: 0.35), Color(red: 0.25, green: 0.50, blue: 0.77)],
            plusColors: [Color(red: 0.776, green: 0.157, blue: 0.157), Color(red: 0.776, green: 0.157, blue: 0.157).opacity(0.87)]
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let designW: CGFloat = 440.44
            let designH: CGFloat = 956
            let widthScale = geo.size.width / designW
            let heightScale = geo.size.height / designH
            let navHeight: CGFloat = 108 * widthScale
            let xScale = widthScale
            let availableHeight = max(geo.size.height - navHeight, 1)
            let yScale = min(heightScale, availableHeight / 863)

            ZStack(alignment: .topLeading) {
                dailyZonesBaseStateOne(xScale: xScale, yScale: yScale)
                    .frame(width: geo.size.width, height: availableHeight, alignment: .top)

                if state == .two {
                    dailyZonesRewardOverlay(geo: geo)
                } else if state == .three {
                    dailyZonesReflectionOverlay(geo: geo)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .preference(key: DailyZonesDimsBottomBarKey.self, value: state == .two || state == .three)
        }
    }

    private func dailyZonesBaseStateOne(xScale: CGFloat, yScale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
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
            .frame(width: 440 * xScale, height: 186 * yScale)
            .position(x: 220 * xScale, y: 93 * yScale)

            VStack(alignment: .leading, spacing: 8 * yScale) {
                Text("Daily Zones")
                    .font(.custom("Outfit-Medium", size: 30 * xScale))
                    .foregroundColor(.white)
                Text("Plan your tiger day across three zones")
                    .font(.system(size: 14 * xScale, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .frame(width: 392.45 * xScale, alignment: .leading)
            .position(x: 220 * xScale, y: 125 * yScale)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16 * yScale) {
                    ForEach(zones) { zone in
                        DailyZoneCard(
                            zone: zone,
                            input: inputBinding(for: zone.zone),
                            tasks: store.zoneTasks(for: zone.zone),
                            isZoneCompleted: store.isZoneCompleted(zone.zone),
                            scale: xScale,
                            verticalScale: yScale,
                            onToggleZone: { store.toggleZoneCompletion(zone.zone) },
                            onAdd: { addTask(to: zone.zone) },
                            onToggleTask: { store.toggleZoneTask(id: $0) },
                            onDeleteTask: { store.deleteZoneTask(id: $0) }
                        )
                    }

                    Button {
                        guard store.canFinishToday else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            state = .three
                        }
                    } label: {
                        Text(store.didFinishToday ? "Day Completed" : "Finish Day")
                            .font(.system(size: 18 * xScale, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 392.45 * xScale, height: 55.98 * yScale)
                            .background((store.canFinishToday && !store.didFinishToday) ? Color(red: 242.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0) : Color.gray.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 16 * xScale, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 10 * xScale, x: 0, y: 4 * yScale)
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canFinishToday || store.didFinishToday)
                    .padding(.top, 8 * yScale)
                    .padding(.bottom, 72 * yScale)
                }
                .frame(width: 392.45 * xScale)
            }
            .frame(width: 392.45 * xScale, height: 600 * yScale)
            .offset(x: 24 * xScale, y: 202 * yScale)
        }
    }

    private func dailyZonesRewardOverlay(geo: GeometryProxy) -> some View {
        let overlayW: CGFloat = 440.44
        let s = geo.size.width / overlayW

        return ZStack {
            Color(red: 82.0 / 255.0, green: 0, blue: 0, opacity: 0.52)
                .ignoresSafeArea()
                .onTapGesture { state = .one }

            Image("Group 548")
                .resizable()
                .scaledToFit()
                .frame(width: 392 * s, height: 382 * s)
                .transition(.scale.combined(with: .opacity))
                .onTapGesture { state = .one }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func dailyZonesReflectionOverlay(geo: GeometryProxy) -> some View {
        let overlayW: CGFloat = 440.44
        let overlayH: CGFloat = 956
        let panelH: CGFloat = 382
        let s = geo.size.width / overlayW
        let topShift: CGFloat = 3
        let centerX = geo.size.width / 2
        let panelCenterY = geo.size.height / 2 + topShift * s
        let panelTopDesign = ((overlayH - panelH) / 2) + topShift
        let panelTop = panelCenterY - (panelH * s / 2)

        let glowTop = panelTop + (449 - panelTopDesign) * s
        let questionTop = panelTop + (395 - panelTopDesign) * s
        let inputTop = panelTop + (478 - panelTopDesign) * s
        let buttonTop = panelTop + (554 - panelTopDesign) * s

        return ZStack(alignment: .topLeading) {
            Color(red: 82.0 / 255.0, green: 0, blue: 0, opacity: 0.52)
                .ignoresSafeArea()
                .onTapGesture { state = .one }

            Image("set-of-chinese-style-ui-frames--fortune-tiger-insp-2 7")
                .resizable()
                .scaledToFit()
                .frame(width: 392 * s, height: 382 * s)
                .position(
                    x: centerX,
                    y: panelCenterY
                )

            Image("game-visual-effects-set--fortune-tiger-style--glow 4")
                .resizable()
                .scaledToFit()
                .frame(width: 142 * s, height: 114 * s)
                .rotationEffect(.degrees(150.93))
                .position(x: centerX, y: glowTop + (114 * s / 2))

            Text("What was the most important thing today?")
                .font(.system(size: 16 * s, weight: .regular))
                .foregroundColor(Color(red: 1.0, green: 229.0 / 255.0, blue: 123.0 / 255.0))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 230 * s, height: 52 * s)
                .position(x: centerX, y: questionTop + (52 * s / 2))

            TextField("", text: $reflectionInput, prompt: Text("It was..")
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459)))
                .font(.system(size: 16 * s, weight: .regular))
                .padding(.horizontal, 16 * s)
                .frame(width: 241 * s, height: 47.99 * s)
                .background(Color(red: 1.0, green: 248.0 / 255.0, blue: 225.0 / 255.0))
                .clipShape(RoundedRectangle(cornerRadius: 20 * s, style: .continuous))
                .position(x: centerX, y: inputTop + (47.99 * s / 2))

            Button {
                store.finishToday(reflection: reflectionInput)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    state = .two
                }
            } label: {
                Text("Go next!")
                    .font(.system(size: 16 * s, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 219 * s, height: 56 * s)
            }
            .buttonStyle(.plain)
            .background(Color(red: 242.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0))
            .clipShape(RoundedRectangle(cornerRadius: 16 * s, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10 * s, x: 0, y: 4 * s)
            .position(x: centerX, y: buttonTop + (56 * s / 2))
        }
        .frame(width: overlayW * s, height: overlayH * s, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func inputBinding(for zone: DayZone) -> Binding<String> {
        switch zone {
        case .morning: return $morningInput
        case .day: return $dayInput
        case .evening: return $eveningInput
        }
    }

    private func addTask(to zone: DayZone) {
        switch zone {
        case .morning:
            store.addZoneTask(zone: zone, title: morningInput)
            morningInput = ""
        case .day:
            store.addZoneTask(zone: zone, title: dayInput)
            dayInput = ""
        case .evening:
            store.addZoneTask(zone: zone, title: eveningInput)
            eveningInput = ""
        }
    }
}

private struct DailyZoneCard: View {
    let zone: ZoneData
    @Binding var input: String
    let tasks: [ZoneTask]
    let isZoneCompleted: Bool
    let scale: CGFloat
    let verticalScale: CGFloat
    let onToggleZone: () -> Void
    let onAdd: () -> Void
    let onToggleTask: (UUID) -> Void
    let onDeleteTask: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8 * verticalScale) {
                HStack(spacing: 12 * scale) {
                    Button(action: onToggleZone) {
                        ZStack {
                        Circle()
                            .fill(Color.white.opacity(isZoneCompleted ? 0.9 : 0.2))
                            .frame(width: 35.98 * scale, height: 35.98 * verticalScale)
                            Image(systemName: isZoneCompleted ? "checkmark" : zone.icon)
                                .font(.system(size: 20 * scale, weight: .regular))
                                .foregroundColor(isZoneCompleted ? .red : .white)
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(zone.title)
                            .font(.custom("Outfit-Medium", size: 18 * scale))
                            .foregroundColor(.white)
                        Text(zone.time)
                            .font(.system(size: 14 * scale))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }

                Text(zone.subtitle)
                    .font(.system(size: 14 * scale))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 20 * scale)
            .padding(.top, 20 * verticalScale)

            HStack(spacing: 8 * scale) {
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.973, blue: 0.882))
                    .frame(height: 35.98 * verticalScale)
                    .overlay {
                        TextField("", text: $input, prompt: Text("Add a task...")
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459)))
                            .font(.system(size: 14 * scale))
                            .padding(.leading, 16 * scale)
                    }

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 20 * scale, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 35.98 * scale, height: 35.98 * verticalScale)
                        .background(
                            LinearGradient(
                                colors: zone.plusColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 3 * scale, x: 0, y: 2 * scale)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16 * scale)
            .padding(.vertical, 16 * verticalScale)
            .padding(.top, 8 * verticalScale)

            VStack(spacing: 8 * verticalScale) {
                ForEach(tasks) { task in
                    DailyZoneTaskRow(
                        task: task,
                        scale: scale,
                        verticalScale: verticalScale,
                        onToggle: { onToggleTask(task.id) },
                        onDelete: { onDeleteTask(task.id) }
                    )
                }
            }
            .padding(.horizontal, 16 * scale)
            .padding(.bottom, 12 * verticalScale)
        }
        .frame(width: 392.45 * scale)
        .frame(minHeight: 183.96 * verticalScale)
        .background(
            LinearGradient(
                colors: zone.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8 * scale, x: 0, y: 4 * scale)
    }
}

private struct DailyZoneTaskRow: View {
    let task: ZoneTask
    let scale: CGFloat
    let verticalScale: CGFloat
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 11.99 * scale) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(Color(red: 1.0, green: 193.0 / 255.0, blue: 7.0 / 255.0), lineWidth: 1.70714 * scale)
                        .frame(width: 20 * scale, height: 20 * verticalScale)
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10 * scale, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 193.0 / 255.0, blue: 7.0 / 255.0))
                    }
                }
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 16 * scale, weight: .regular))
                .foregroundColor(task.isCompleted ? Color(red: 0.459, green: 0.459, blue: 0.459) : Color(red: 0.102, green: 0.102, blue: 0.102))
                .lineLimit(1)
                .strikethrough(task.isCompleted, color: Color(red: 0.459, green: 0.459, blue: 0.459))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 14 * scale, weight: .regular))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    .frame(width: 16 * scale, height: 16 * verticalScale)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 11.9945 * scale)
        .frame(width: 360.46 * scale, height: 47.98 * verticalScale)
        .background(task.isCompleted ? Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0).opacity(0.5) : Color(red: 1.0, green: 248.0 / 255.0, blue: 225.0 / 255.0))
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
    }
}

#Preview {
    DailyZonesScreenView()
        .environmentObject(FortuneWildStore())
}
