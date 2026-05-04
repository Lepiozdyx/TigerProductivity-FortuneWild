import SwiftUI

struct TigerLevelsScreenView: View {
    @EnvironmentObject private var store: FortuneWildStore

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 440
            let contentHeight: CGFloat = 1128.9 * scale

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    header(scale: scale)

                    featuredLevelCard(scale: scale)
                        .position(x: (18 + 204) * scale, y: (207 + 223.5) * scale)

                    allLevelsBlock(scale: scale)
                        .position(x: (24 + 392.45 / 2) * scale, y: (637 + 245.95) * scale)
                }
                .frame(width: geo.size.width, height: contentHeight, alignment: .top)
                .padding(.bottom, 120 * scale)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private func header(scale: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 32 * scale,
                bottomTrailingRadius: 32 * scale,
                topTrailingRadius: 0
            )
            .fill(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.0, blue: 0.0), Color(red: 0.714, green: 0.0, blue: 0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 440 * scale, height: 186 * scale)
            .shadow(color: .black.opacity(0.12), radius: 8 * scale, x: 0, y: 4 * scale)

            VStack(alignment: .leading, spacing: 8 * scale) {
                Text("Tiger Levels")
                    .font(.custom("Outfit-Medium", size: 30 * scale))
                    .foregroundColor(.white)
                Text("Grow your tiger through achievements")
                    .font(.system(size: 14 * scale))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 392.45 * scale, alignment: .leading)
            .padding(.leading, 24 * scale)
            .padding(.bottom, 24 * scale)
        }
        .position(x: 220 * scale, y: 93 * scale)
    }

    private func featuredLevelCard(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                        .stroke(Color.red, lineWidth: 4 * scale)
                )
                .shadow(color: .black.opacity(0.25), radius: 25 * scale, x: 0, y: 10 * scale)

            VStack(alignment: .leading, spacing: 12 * scale) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4 * scale) {
                        Text("Level \(store.currentLevel.id)")
                            .font(.system(size: 14 * scale))
                            .foregroundColor(Color(red: 0.255, green: 0.0, blue: 0.0).opacity(0.8))
                        Text(store.currentLevel.title)
                            .font(.custom("Outfit-Medium", size: 30 * scale))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.851, blue: 0.376)) // #FFD960
                        Image(systemName: "trophy")
                            .font(.system(size: 31.99 * scale, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .frame(width: 55.98 * scale, height: 55.98 * scale)
                }

                VStack(alignment: .leading, spacing: 8 * scale) {
                    HStack {
                        Text(store.nextLevel.map { "\(store.state.points) / \($0.minPoints) XP" } ?? "\(store.state.points) XP")
                            .font(.system(size: 14 * scale))
                            .foregroundColor(Color(red: 0.576, green: 0.0, blue: 0.0).opacity(0.9))
                        Spacer()
                        Text("\(Int((store.progressToNextLevel * 100).rounded()))%")
                            .font(.system(size: 14 * scale))
                            .foregroundColor(Color(red: 0.576, green: 0.0, blue: 0.0).opacity(0.9))
                    }

                    Capsule()
                        .fill(Color(red: 1.0, green: 0.851, blue: 0.376))
                        .frame(height: 12 * scale)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.red)
                                .frame(width: 344.45 * CGFloat(store.progressToNextLevel) * scale, height: 12 * scale)
                        }
                }

                Text(store.nextLevel.map { "\($0.minPoints - store.state.points) XP to \($0.title)" } ?? "Maximum tiger level reached")
                    .font(.system(size: 14 * scale))
                    .foregroundColor(Color(red: 0.255, green: 0.0, blue: 0.0).opacity(0.8))
            }
            .padding(.horizontal, 25 * scale)
            .padding(.top, 24 * scale)

            Image("set-of-stylized-tiger-forms-for-mobile-game--fortu-2 3")
                .resizable()
                .scaledToFit()
                .frame(width: 248 * scale, height: 254 * scale)
                .position(x: (80 + 124) * scale, y: (176 + 127) * scale)
        }
        .frame(width: 408 * scale, height: 447 * scale)
    }

    private func allLevelsBlock(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            Text("ALL LEVELS")
                .font(.custom("Outfit-Medium", size: 14 * scale))
                .tracking(0.35 * scale)
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))

            ZStack(alignment: .topLeading) {
                ForEach(Array(TigerLevel.all.enumerated()), id: \.element.id) { index, level in
                    let active = level.id == store.currentLevel.id
                    levelRow(title: "\(level.icon) \(level.title)", xp: level.rangeTitle, active: active, scale: scale)
                        .position(
                            x: (active ? -8.61 + 361.2 / 2 : 344.45 / 2) * scale,
                            y: (CGFloat(index) * 83.98 + (active ? 75.6 / 2 : 71.98 / 2)) * scale
                        )
                }
            }
            .frame(width: 344.45 * scale, height: 407.9 * scale, alignment: .top)
        }
        .padding(.horizontal, 23.9978 * scale)
        .padding(.top, 23.9978 * scale)
        .frame(width: 392.45 * scale, height: 491.9 * scale, alignment: .topLeading)
    }

    private func levelRow(title: String, xp: String, active: Bool, scale: CGFloat) -> some View {
        HStack(spacing: (active ? 16.8 : 16) * scale) {
            ZStack {
                RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
                Image(systemName: "trophy")
                    .font(.system(size: (active ? 25.2 : 24) * scale, weight: .medium))
                    .foregroundColor(
                        active
                            ? Color(red: 1.0, green: 0.835, blue: 0.31)
                            : Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0)
                    )
            }
            .frame(width: (active ? 50.4 : 48) * scale, height: (active ? 50.4 : 48) * scale)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8.39 * scale) {
                    Text(title)
                        .font(.custom("Outfit-Medium", size: 16 * scale))
                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    if active {
                        Text("Current")
                            .font(.system(size: 12 * scale))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8 * scale)
                            .padding(.vertical, 2 * scale)
                    }
                }
                Text(xp)
                    .font(.system(size: 12 * scale))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, (active ? 12.5942 : 11.9945) * scale)
        .padding(.vertical, (active ? 12 : 12) * scale)
        .frame(width: active ? 361.2 * scale : 344.45 * scale, height: active ? 75.6 * scale : 71.98 * scale)
        .background {
            if active {
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.0), location: 0.00),
                        .init(color: Color(red: 1.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0).opacity(0.0714286), location: 0.0714),
                        .init(color: Color(red: 10.0 / 255.0, green: 7.0 / 255.0, blue: 4.0 / 255.0).opacity(0.142857), location: 0.1429),
                        .init(color: Color(red: 25.0 / 255.0, green: 21.0 / 255.0, blue: 14.0 / 255.0).opacity(0.214286), location: 0.2143),
                        .init(color: Color(red: 42.0 / 255.0, green: 36.0 / 255.0, blue: 26.0 / 255.0).opacity(0.285714), location: 0.2857),
                        .init(color: Color(red: 60.0 / 255.0, green: 52.0 / 255.0, blue: 39.0 / 255.0).opacity(0.357143), location: 0.3571),
                        .init(color: Color(red: 79.0 / 255.0, green: 69.0 / 255.0, blue: 53.0 / 255.0).opacity(0.428571), location: 0.4286),
                        .init(color: Color(red: 99.0 / 255.0, green: 86.0 / 255.0, blue: 67.0 / 255.0).opacity(0.5), location: 0.5),
                        .init(color: Color(red: 120.0 / 255.0, green: 104.0 / 255.0, blue: 81.0 / 255.0).opacity(0.571429), location: 0.5714),
                        .init(color: Color(red: 141.0 / 255.0, green: 123.0 / 255.0, blue: 97.0 / 255.0).opacity(0.642857), location: 0.6429),
                        .init(color: Color(red: 163.0 / 255.0, green: 142.0 / 255.0, blue: 112.0 / 255.0).opacity(0.714286), location: 0.7143),
                        .init(color: Color(red: 185.0 / 255.0, green: 162.0 / 255.0, blue: 128.0 / 255.0).opacity(0.785714), location: 0.7857),
                        .init(color: Color(red: 208.0 / 255.0, green: 182.0 / 255.0, blue: 144.0 / 255.0).opacity(0.857143), location: 0.8571),
                        .init(color: Color(red: 231.0 / 255.0, green: 203.0 / 255.0, blue: 161.0 / 255.0).opacity(0.928571), location: 0.9286),
                        .init(color: Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0), location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color(red: 1.0, green: 224.0 / 255.0, blue: 178.0 / 255.0).opacity(0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
    }
}

#Preview {
    TigerLevelsScreenView()
        .environmentObject(FortuneWildStore())
}
