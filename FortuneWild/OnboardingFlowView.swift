import SwiftUI

private let onboardingRed = Color(red: 1.0, green: 0.0, blue: 0.0)

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let characterImage: String
}

struct OnboardingFlowView: View {
    @State private var currentPage = 0
    var onFinish: () -> Void = {}

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Hunt your tasks",
            subtitle: "Focus like a tiger. Strike fast. Rest smart.",
            characterImage: "cute-cartoon-tiger-character-set--inspired-by-fort 4"
        ),
        OnboardingSlide(
            title: "Quick Hunts",
            subtitle: "Complete small tasks in 5-10 minutes",
            characterImage: "tiger-2"
        ),
        OnboardingSlide(
            title: "Deep Focus",
            subtitle: "Work in cycles: 25 min focus + 5 min rest",
            characterImage: "cute-cartoon-tiger-character-set--inspired-by-fort 5"
        ),
        OnboardingSlide(
            title: "Ready to roar?",
            subtitle: "Start your first hunt and keep the streak alive.",
            characterImage: "tiger"
        )
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                OnboardingSlideView(
                    slide: slide,
                    slideIndex: index,
                    currentPage: currentPage,
                    totalPages: slides.count,
                    onSkip: {
                        withAnimation(.easeInOut) {
                            currentPage = slides.count - 1
                        }
                    },
                    onNext: {
                        withAnimation(.easeInOut) {
                            if currentPage < slides.count - 1 {
                                currentPage += 1
                            } else {
                                onFinish()
                            }
                        }
                    },
                    buttonTitle: index == 0 ? "Get Started" : (index == 1 || index == 2 ? "Next" : "Finish")
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let slideIndex: Int
    let currentPage: Int
    let totalPages: Int
    let onSkip: () -> Void
    let onNext: () -> Void
    let buttonTitle: String

    var body: some View {
        GeometryReader { geo in
            if slideIndex == 1 {
                secondScreenLayout(in: geo.size)
            } else if slideIndex == 2 {
                thirdScreenLayout(in: geo.size)
            } else if slideIndex == 3 {
                fourthScreenLayout(in: geo.size)
            } else {
                defaultScreenLayout(in: geo)
            }
        }
    }

    private func secondScreenLayout(in size: CGSize) -> some View {
        let scale = min(size.width / 440, size.height / 956)
        let offsetX = (size.width - 440 * scale) / 2
        let offsetY = (size.height - 956 * scale) / 2
        let maxTextWidth = max(size.width - 20, 0)

        return ZStack(alignment: .topLeading) {
            Image("Quick Hunt")
                .resizable()
                .ignoresSafeArea()

            navigationDots(scaleX: 1, scaleY: 1)
                .frame(width: 79.95, height: 7.99)
                .position(x: offsetX + (172 + 39.975) * scale, y: offsetY + (79 + 3.995) * scale)

            // Decorative images ordered by CSS indexes 1...7.
            positionedImageAbsolute("1", left: 321.78, top: 77.43, width: 68, height: 73, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: 3.34)
            positionedImageAbsolute("2", left: 242, top: 111, width: 38.6, height: 41.19, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: 3.34)
            positionedImageAbsolute("3", left: 192, top: 82, width: 250, height: 240, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: 0)
            positionedImageAbsolute("4", left: 333.66, top: 526.82, width: 68, height: 73, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: -45)
            positionedImageAbsolute("5", left: 0, top: 473, width: 131, height: 146, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: -24)
            positionedImageAbsolute("6", left: 28.68, top: 239.47, width: 95, height: 102, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: -25.85)
            positionedImageAbsolute("7", left: 68.64, top: 166.31, width: 68, height: 73, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: 26)
            positionedImageAbsolute("tiger-2", left: 26, top: 286, width: 381.82, height: 300, scale: scale, offsetX: offsetX, offsetY: offsetY, rotation: 0)

            Text("Quick Hunts")
                .font(.custom("Outfit-Medium", size: 36))
                .foregroundStyle(onboardingRed)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .frame(width: min(192.27, maxTextWidth), height: 39.99)
                .position(x: offsetX + (125.78 + 96.135) * scale, y: offsetY + (604 + 19.995) * scale)

            Text("Complete small tasks in 5–10 minutes")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(red: 0.286, green: 0.0, blue: 0.0))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)
                .frame(width: min(339.83, maxTextWidth), height: 27.99)
                .position(x: offsetX + (52 + 169.915) * scale, y: offsetY + (659.99 + 13.995) * scale)

            actionButton(title: "Next", width: 392.45 * scale, height: 59.98 * scale)
                .position(x: offsetX + (24 + 196.225) * scale, y: offsetY + (763 + 29.99) * scale)

            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .position(x: offsetX + (199 + 18) * scale, y: offsetY + (841 + 14) * scale)
        }
        .frame(width: size.width, height: size.height)
    }

    private func defaultScreenLayout(in geo: GeometryProxy) -> some View {
        ZStack {
            Image("Quick Hunt")
                .resizable()
                .ignoresSafeArea()

            if slideIndex == 1 {
                secondScreenImageLayer(in: geo.size)
            }

            VStack(spacing: 0) {
                Spacer().frame(height: geo.safeAreaInsets.top + 24)
                navigationDots(scaleX: 1, scaleY: 1)
                Spacer().frame(height: slideIndex == 1 ? 30 : 48)

                Image(slide.characterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: min(geo.size.width * (slideIndex == 1 ? 0.88 : 0.8), slideIndex == 1 ? 382 : 350),
                        maxHeight: slideIndex == 1 ? 300 : 330
                    )
                    .offset(y: slideIndex == 1 ? 12 : 0)
                    .opacity(slideIndex == 1 ? 0 : 1)

                Spacer().frame(height: 24)

                Text(slide.title)
                    .font(.custom("Outfit-Medium", size: 36))
                    .foregroundStyle(onboardingRed)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 10)

                Spacer().frame(height: 12)

                Text(slide.subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(red: 0.33, green: 0.0, blue: 0.0))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .padding(.horizontal, 10)

                Spacer().frame(height: 56)

                actionButton(title: buttonTitle, width: nil, height: 60)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 22)

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                }

                Spacer().frame(height: geo.safeAreaInsets.bottom + 18)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    private func thirdScreenLayout(in size: CGSize) -> some View {
        let scale = min(size.width / 440, size.height / 956)
        let offsetX = (size.width - 440 * scale) / 2
        let offsetY = (size.height - 956 * scale) / 2
        let isSmallWidth = size.width <= 375
        let maxTextWidth = max(size.width - 20, 0)

        return ZStack(alignment: .topLeading) {
            Image("Quick Hunt")
                .resizable()
                .ignoresSafeArea()

            navigationDots(scaleX: 1, scaleY: 1)
                .frame(width: 80, height: 8)
                .position(x: offsetX + (157 + 40) * scale, y: offsetY + (81 + 4) * scale)

            positionedImageAbsolute(
                slide.characterImage,
                left: -12,
                top: 196.25,
                width: 432,
                height: 378,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: 0
            )

            Text(slide.title)
                .font(.custom("Outfit-Medium", size: 36))
                .foregroundStyle(onboardingRed)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(isSmallWidth ? 0.7 : 1.0)
                .allowsTightening(true)
                .frame(width: min(240, maxTextWidth), height: 40)
                .position(x: offsetX + (127.83 + 92.5) * scale, y: offsetY + (607 + 20) * scale)

            Text(slide.subtitle)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(red: 0.494, green: 0.0, blue: 0.0))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(isSmallWidth ? 0.55 : 1.0)
                .allowsTightening(true)
                .frame(width: min(330, maxTextWidth), height: 28)
                .position(x: offsetX + (39.66 + 180.555) * scale, y: offsetY + (662.99 + 14) * scale)

            actionButton(title: "Next", width: 392.45 * scale, height: 59.98 * scale)
                .position(x: offsetX + (24 + 196.225) * scale, y: offsetY + (765 + 29.99) * scale)

            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
            }
            .position(x: offsetX + (202 + 18) * scale, y: offsetY + (841 + 14) * scale)
        }
        .frame(width: size.width, height: size.height)
    }

    private func fourthScreenLayout(in size: CGSize) -> some View {
        let scale = min(size.width / 440, size.height / 956)
        let offsetX = (size.width - 440 * scale) / 2
        let offsetY = (size.height - 956 * scale) / 2
        let maxTextWidth = max(size.width - 20, 0)

        return ZStack(alignment: .topLeading) {
            Image("Quick Hunt")
                .resizable()
                .ignoresSafeArea()

            navigationDots(scaleX: 1, scaleY: 1)
                .frame(width: 80, height: 8)
                .position(x: offsetX + (154 + 40) * scale, y: offsetY + (84 + 4) * scale)

            positionedImageAbsolute(
                "set-of-stylized-tiger-forms-for-mobile-game--fortu-2 7",
                left: 170,
                top: 280,
                width: 252,
                height: 260,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: 0
            )

            positionedImageAbsolute(
                "tiger-evolution-stages--cute-cartoon-style-inspire 4",
                left: 50,
                top: 410,
                width: 110,
                height: 120,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: 0
            )

            positionedImageAbsolute(
                "Arrow 1",
                left: 58,
                top: 322,
                width: 185.64,
                height: 70.08,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: 0
            )

            Text("Grow Your Tiger")
                .font(.custom("Outfit-Medium", size: 36))
                .foregroundStyle(onboardingRed)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .allowsTightening(true)
                .frame(width: min(261, maxTextWidth), height: 40)
                .position(x: offsetX + (85.61 + 130.5) * scale, y: offsetY + (610.17 + 20) * scale)

            Text("Earn points. Unlock levels. Become legendary.")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(red: 0.376, green: 0.0, blue: 0.0))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .frame(width: min(383.99, maxTextWidth), height: 55.98)
                .position(x: offsetX + (24 + 191.995) * scale, y: offsetY + (666 + 27.99) * scale)

            actionButton(title: "Start Hunting", width: 392.45 * scale, height: 59.98 * scale)
                .position(x: offsetX + (24 + 196.225) * scale, y: offsetY + (800 + 29.99) * scale)
        }
        .frame(width: size.width, height: size.height)
    }

    private func navigationDots(scaleX: CGFloat, scaleY: CGFloat) -> some View {
        HStack(spacing: 8 * scaleX) {
            ForEach(0..<totalPages, id: \.self) { idx in
                Circle()
                    .fill(Color.red.opacity(idx == currentPage ? 1 : 0.55))
                    .frame(
                        width: (idx == currentPage ? 14 : 8) * scaleX,
                        height: (idx == currentPage ? 14 : 8) * scaleY
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private func actionButton(title: String, width: CGFloat?, height: CGFloat) -> some View {
        Button(action: onNext) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(width: width, height: height)
            .background(onboardingRed)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private func secondScreenImageLayer(in size: CGSize) -> some View {
        let sx = size.width / 440
        let sy = size.height / 956

        ZStack(alignment: .topLeading) {
            positionedImage("1", left: 199.83, top: 52.81, width: 224, height: 215, sx: sx, sy: sy, rotation: 22.06)
            positionedImage("2", left: 321.78, top: 77.43, width: 68, height: 73, sx: sx, sy: sy, rotation: 3.34)
            positionedImage("3", left: 242, top: 111, width: 38.6, height: 41.19, sx: sx, sy: sy, rotation: 3.34)
            positionedImage("4", left: 333.66, top: 526.82, width: 68, height: 73, sx: sx, sy: sy, rotation: -45)
            positionedImage("5", left: 0, top: 473, width: 131, height: 146, sx: sx, sy: sy, rotation: -24)
            positionedImage("6", left: 28.68, top: 239.47, width: 95, height: 102, sx: sx, sy: sy, rotation: -25.85)
            positionedImage("7", left: 68.64, top: 166.31, width: 68, height: 73, sx: sx, sy: sy, rotation: 26)
            positionedImage("tiger-2", left: 26, top: 286, width: 381.82, height: 300, sx: sx, sy: sy, rotation: 0)
        }
        .frame(width: size.width, height: size.height)
    }

    private func positionedImage(
        _ name: String,
        left: CGFloat,
        top: CGFloat,
        width: CGFloat,
        height: CGFloat,
        sx: CGFloat,
        sy: CGFloat,
        rotation: Double
    ) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width * sx, height: height * sy)
            .rotationEffect(.degrees(rotation))
            .position(
                x: (left + width / 2) * sx,
                y: (top + height / 2) * sy
            )
    }

    private func positionedImageAbsolute(
        _ name: String,
        left: CGFloat,
        top: CGFloat,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        rotation: Double
    ) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width * scale, height: height * scale)
            .rotationEffect(.degrees(rotation))
            .position(
                x: offsetX + (left + width / 2) * scale,
                y: offsetY + (top + height / 2) * scale
            )
    }
}

#Preview {
    OnboardingFlowView()
}
