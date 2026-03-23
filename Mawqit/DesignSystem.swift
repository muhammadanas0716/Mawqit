import SwiftUI

enum MawqitTheme {
    static let accentSun = Color(red: 0.48, green: 0.76, blue: 0.55)
    static let accentSky = Color(red: 0.31, green: 0.61, blue: 0.49)
    static let accentCoral = Color(red: 0.67, green: 0.78, blue: 0.49)

    static let ink = Color(red: 0.93, green: 0.97, blue: 0.94)
    static let mutedInk = Color(red: 0.60, green: 0.69, blue: 0.64)
    static let inkOnAccent = Color(red: 0.05, green: 0.11, blue: 0.08)

    static let card = Color(red: 0.07, green: 0.12, blue: 0.10).opacity(0.92)
    static let cardRaised = Color(red: 0.09, green: 0.16, blue: 0.12).opacity(0.96)
    static let cardStroke = Color(red: 0.42, green: 0.58, blue: 0.48).opacity(0.24)
    static let cardHighlight = Color.white.opacity(0.05)
    static let cardShadow = Color.black.opacity(0.44)
    static let inputFill = Color(red: 0.10, green: 0.17, blue: 0.13).opacity(0.98)

    static let backgroundTop = Color(red: 0.02, green: 0.05, blue: 0.04)
    static let backgroundMid = Color(red: 0.04, green: 0.10, blue: 0.08)
    static let backgroundBottom = Color(red: 0.07, green: 0.16, blue: 0.12)

    static let readerBackground = Color(red: 0.03, green: 0.07, blue: 0.05)
    static let readerSurface = Color(red: 0.09, green: 0.15, blue: 0.11)
    static let readerBorder = Color(red: 0.44, green: 0.58, blue: 0.47).opacity(0.26)
    static let readerText = Color(red: 0.86, green: 0.93, blue: 0.86)
    static let readerSecondaryText = Color(red: 0.62, green: 0.73, blue: 0.66)
}

struct MawqitSkyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MawqitTheme.backgroundTop,
                    MawqitTheme.backgroundMid,
                    MawqitTheme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    MawqitTheme.accentSun.opacity(0.34),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 320
            )
            .offset(x: -90, y: -140)

            RadialGradient(
                colors: [
                    MawqitTheme.accentSky.opacity(0.28),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 280
            )
            .offset(x: 90, y: 180)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            MawqitTheme.accentCoral.opacity(0.16),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 340, height: 220)
                .blur(radius: 20)
                .rotationEffect(.degrees(-12))
                .offset(x: 100, y: -280)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxHeight: .infinity, alignment: .top)
                .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }
}

struct MawqitCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(MawqitTheme.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MawqitTheme.cardHighlight,
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MawqitTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: MawqitTheme.cardShadow, radius: 20, x: 0, y: 14)
    }
}

extension View {
    func mawqitCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(MawqitCardModifier(cornerRadius: cornerRadius))
    }
}
