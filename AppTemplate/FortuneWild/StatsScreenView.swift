import SwiftUI

private let statsAccent = Color(red: 0.973, green: 0.004, blue: 0.004)

private func finiteCGFloat(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
    value.isFinite ? value : fallback
}

private func unitCGFloat(_ value: CGFloat) -> CGFloat {
    min(max(finiteCGFloat(value), 0), 1)
}

struct StatsScreenView: View {
    @EnvironmentObject private var store: FortuneWildStore

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 440

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24 * scale) {
                    header(scale: scale)

                    VStack(spacing: 24 * scale) {
                        metricsGrid(scale: scale)

                        LineChartCardView(
                            title: "Weekly Activity",
                            yLabels: ["8", "6", "4", "2", "0"],
                            points: store.activityLastSevenDays().map { CGFloat($0) },
                            lineColor: Color(red: 1.0, green: 0.56, blue: 0),
                            scale: scale
                        )

                        LineChartCardView(
                            title: "Focus Time (minutes)",
                            yLabels: ["160", "120", "80", "40", "0"],
                            points: store.focusMinutesLastSevenDays().map { CGFloat($0) },
                            lineColor: Color(red: 1.0, green: 0.757, blue: 0.027),
                            scale: scale
                        )

                        MoodCardView(moods: store.moodBreakdown(), scale: scale)
                        TasksByZoneCardView(zones: store.zoneBreakdown(), favorite: store.favoriteZone, scale: scale)
                    }
                    .padding(.horizontal, 24 * scale)
                }
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
                    colors: [Color(red: 1.0, green: 0.0, blue: 0.0), Color(red: 0.714, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 186 * scale)
            .shadow(color: .black.opacity(0.16), radius: 8 * scale, x: 0, y: 4 * scale)

            VStack(alignment: .leading, spacing: 8 * scale) {
                Text("Your Stats")
                    .font(.custom("Outfit-Medium", size: 30 * scale))
                    .foregroundColor(.white)
                Text("Track your tiger journey")
                    .font(.system(size: 14 * scale, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 24 * scale)
            .padding(.bottom, 25 * scale)
        }
        .frame(maxWidth: .infinity)
    }

    private func metricsGrid(scale: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16 * scale), count: 2), spacing: 16 * scale) {
            MetricCard(
                title: "Total Tasks",
                value: "\(store.totalCompletedTasks)",
                icon: "target",
                iconColor: Color(red: 1.0, green: 0.56, blue: 0),
                iconBg: Color(red: 1.0, green: 0.56, blue: 0).opacity(0.12),
                scale: scale
            )
            MetricCard(
                title: "Focus Cycles",
                value: "\(store.totalFocusCycles)",
                icon: "flame",
                iconColor: Color(red: 0.898, green: 0.224, blue: 0.208),
                iconBg: Color(red: 0.898, green: 0.224, blue: 0.208).opacity(0.12),
                scale: scale
            )
            MetricCard(
                title: "Avg Focus",
                value: "\(store.averageFocusMinutes)m",
                icon: "clock",
                iconColor: Color(red: 1.0, green: 0.757, blue: 0.027),
                iconBg: Color(red: 1.0, green: 0.757, blue: 0.027).opacity(0.12),
                scale: scale
            )
            MetricCard(
                title: "Level",
                value: store.currentLevel.title,
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color(red: 0.776, green: 0.157, blue: 0.157),
                iconBg: Color(red: 0.776, green: 0.157, blue: 0.157).opacity(0.12),
                scale: scale
            )
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            HStack(spacing: 12 * scale) {
                ZStack {
                    Circle().fill(iconBg)
                    Image(systemName: icon)
                        .font(.system(size: 18 * scale, weight: .regular))
                        .foregroundColor(iconColor)
                }
                .frame(width: 36 * scale, height: 36 * scale)

                Text(title)
                    .font(.system(size: 14 * scale))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }

            Text(value)
                .font(.system(size: 30 * scale, weight: .regular))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
        }
        .padding(20 * scale)
        .frame(maxWidth: .infinity, minHeight: 120 * scale, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4 * scale, x: 0, y: 2 * scale)
    }
}

private struct LineChartCardView: View {
    let title: String
    let yLabels: [String]
    let points: [CGFloat]
    let lineColor: Color
    let scale: CGFloat

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            Text(title)
                .font(.custom("Outfit-Medium", size: 18 * scale))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))

            ChartPlot(yLabels: yLabels, xLabels: days, points: points, lineColor: lineColor, scale: scale)
                .frame(height: 220 * scale)
        }
        .padding(24 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8 * scale, x: 0, y: 4 * scale)
    }
}

private struct ChartPlot: View {
    let yLabels: [String]
    let xLabels: [String]
    let points: [CGFloat]
    let lineColor: Color
    let scale: CGFloat

    var body: some View {
        GeometryReader { geo in
            let leftPad = 36 * scale
            let bottomPad = 28 * scale
            let topPad = 8 * scale
            let rightPad = 8 * scale
            let plotW = max(geo.size.width - leftPad - rightPad, 1)
            let plotH = max(geo.size.height - topPad - bottomPad, 1)
            let safePoints = points.map { finiteCGFloat($0) }
            let maxPoint = max(safePoints.max() ?? 1, 1)
            let chartPoints: [CGPoint] = points.indices.map { idx in
                CGPoint(
                    x: leftPad + (plotW / CGFloat(max(points.count - 1, 1))) * CGFloat(idx),
                    y: topPad + plotH - (safePoints[idx] / maxPoint) * plotH
                )
            }

            ZStack {
                // Grid
                ForEach(0..<5, id: \.self) { i in
                    let y = topPad + (plotH / 4) * CGFloat(i)
                    Path { p in
                        p.move(to: CGPoint(x: leftPad, y: y))
                        p.addLine(to: CGPoint(x: leftPad + plotW, y: y))
                    }
                    .stroke(Color(red: 0.898, green: 0.906, blue: 0.922), style: StrokeStyle(lineWidth: 1 * scale, dash: [4 * scale, 3 * scale]))
                }

                ForEach(0..<7, id: \.self) { i in
                    let x = leftPad + (plotW / 6) * CGFloat(i)
                    Path { p in
                        p.move(to: CGPoint(x: x, y: topPad))
                        p.addLine(to: CGPoint(x: x, y: topPad + plotH))
                    }
                    .stroke(Color(red: 0.898, green: 0.906, blue: 0.922), style: StrokeStyle(lineWidth: 1 * scale, dash: [4 * scale, 3 * scale]))
                }

                // Axes labels
                ForEach(0..<yLabels.count, id: \.self) { i in
                    Text(yLabels[i])
                        .font(.system(size: 12 * scale))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        .position(x: 12 * scale, y: topPad + (plotH / 4) * CGFloat(i))
                }

                ForEach(0..<xLabels.count, id: \.self) { i in
                    Text(xLabels[i])
                        .font(.system(size: 12 * scale))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        .position(x: leftPad + (plotW / 6) * CGFloat(i), y: topPad + plotH + 14 * scale)
                }

                // Straight segments avoid spline overshoot, so the chart never shows motion
                // that is not present in the actual daily values.
                Path { p in
                    guard let first = chartPoints.first else { return }
                    p.move(to: first)
                    for point in chartPoints.dropFirst() {
                        p.addLine(to: point)
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round))

                // Dots
                ForEach(chartPoints.indices, id: \.self) { idx in
                    let point = chartPoints[idx]
                    Circle()
                        .fill(lineColor)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5 * scale)
                        )
                        .frame(width: 14 * scale, height: 14 * scale)
                        .position(x: point.x, y: point.y)
                }
            }
        }
    }
}

private struct MoodCardView: View {
    let moods: [(feeling: TigerFeeling, count: Int, percent: Int)]
    let scale: CGFloat
    private let colors: [Color] = [
        Color(red: 1.0, green: 0.835, blue: 0.31),
        Color(red: 1.0, green: 0.56, blue: 0),
        Color(red: 1.0, green: 0.757, blue: 0.027),
        Color(red: 0.776, green: 0.157, blue: 0.157)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            Text("Mood After Tasks")
                .font(.custom("Outfit-Medium", size: 18 * scale))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))

            HStack(spacing: 20 * scale) {
                donut
                    .frame(width: 112 * scale, height: 112 * scale)

                VStack(spacing: 12 * scale) {
                    ForEach(Array(moods.enumerated()), id: \.element.feeling.id) { index, mood in
                        HStack(spacing: 12 * scale) {
                            Image(mood.feeling.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24 * scale, height: 24 * scale)

                            VStack(alignment: .leading, spacing: 4 * scale) {
                                HStack {
                                    Text(mood.feeling.title)
                                        .font(.system(size: 14 * scale))
                                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                                    Spacer()
                                    Text("\(mood.percent)%")
                                        .font(.system(size: 12 * scale))
                                        .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                                }
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.878, blue: 0.698))
                                    .frame(height: 8 * scale)
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(colors[index % colors.count])
                                            .frame(width: unitCGFloat(CGFloat(mood.percent) / 100) * 104 * scale, height: 8 * scale)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .padding(24 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8 * scale, x: 0, y: 4 * scale)
    }

    private var donut: some View {
        let ringWidth = 30 * scale
        let total = moods.reduce(0) { $0 + $1.count }

        return ZStack {
            if total == 0 {
                Circle()
                    .stroke(Color(red: 1.0, green: 0.878, blue: 0.698), style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt, lineJoin: .miter))
            } else {
                let raw = moods.map { Double($0.count) / Double(total) }
                let gap = 0.01152
                let starts: [CGFloat] = raw.indices.map { index in
                    CGFloat(raw.prefix(index).reduce(0, +))
                }

                ForEach(starts.indices, id: \.self) { index in
                    if moods[index].count > 0 {
                        let start = unitCGFloat(starts[index])
                        let end = unitCGFloat(start + CGFloat(max(raw[index] - gap, 0.001)))
                    segment(start: start, end: end, color: colors[index % colors.count])
                    }
                }

                ForEach(starts.indices, id: \.self) { index in
                    if moods[index].count > 0 {
                        let boundary = unitCGFloat(starts[index])
                    segment(
                        start: unitCGFloat(boundary - 0.0016),
                        end: unitCGFloat(boundary + 0.0016),
                        color: .white,
                        lineWidth: ringWidth + 1 * scale
                    )
                    }
                }
            }

            Circle()
                .fill(.white)
                .padding(41 * scale)
        }
    }

    private func segment(start: CGFloat, end: CGFloat, color: Color, lineWidth: CGFloat? = nil) -> some View {
        let safeStart = unitCGFloat(start)
        let safeEnd = max(unitCGFloat(end), safeStart)
        let safeLineWidth = max(finiteCGFloat(lineWidth ?? 30 * scale), 0.1)

        return Circle()
            .trim(from: safeStart, to: safeEnd)
            .stroke(color, style: StrokeStyle(lineWidth: safeLineWidth, lineCap: .butt, lineJoin: .miter))
            .rotationEffect(.degrees(-90))
    }
}

private struct TasksByZoneCardView: View {
    let zones: [(zone: DayZone, count: Int, progress: Double)]
    let favorite: DayZone?
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            Text("Tasks by Time Zone")
                .font(.custom("Outfit-Medium", size: 18 * scale))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))

            ForEach(Array(zones.enumerated()), id: \.element.zone.id) { index, item in
                zoneRow(
                    name: item.zone.shortTitle,
                    value: "\(item.count) tasks",
                    progress: unitCGFloat(CGFloat(item.progress)),
                    color: zoneColor(index)
                )
            }

            VStack(alignment: .leading, spacing: 4 * scale) {
                Text("Favorite Zone")
                    .font(.system(size: 14 * scale))
                    .foregroundColor(Color.red.opacity(0.9))
                Text(favorite.map { "🌅 \($0.title)" } ?? "No favorite yet")
                    .font(.system(size: 20 * scale))
                    .foregroundColor(Color.red)
                Text(favorite == nil ? "Complete zone tasks to reveal your pattern." : "You're most productive in this zone!")
                    .font(.system(size: 12 * scale))
                    .foregroundColor(Color(red: 0.58, green: 0.0, blue: 0.0).opacity(0.8))
            }
            .padding(16 * scale)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
        }
        .padding(24 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8 * scale, x: 0, y: 4 * scale)
    }

    private func zoneRow(name: String, value: String, progress: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            HStack {
                Text(name)
                    .font(.system(size: 14 * scale))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                Spacer()
                Text(value)
                    .font(.system(size: 14 * scale))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }

            Capsule()
                .fill(Color(red: 1.0, green: 0.878, blue: 0.698))
                .frame(height: 12 * scale)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: progress * 344 * scale, height: 12 * scale)
                }
        }
    }

    private func zoneColor(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.757, blue: 0.027)
        case 1: return Color(red: 1.0, green: 0.56, blue: 0)
        default: return Color(red: 0.776, green: 0.157, blue: 0.157)
        }
    }
}

#Preview {
    StatsScreenView()
        .environmentObject(FortuneWildStore())
}
