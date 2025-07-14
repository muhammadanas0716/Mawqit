//
//  OnboardingView.swift
//  Mawqit
//
//  Dark-theme – 14 Jul 2025
//

import SwiftUI

// Same palette used in ContentView
private let primaryGreen   = Color(red: 0.10, green: 0.55, blue: 0.44)   // #198C71
private let glass          = Color.white.opacity(0.05)
private let glassStroke    = Color.white.opacity(0.10)

struct OnboardingView: View {
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()                       // pure dark bg

            VStack(spacing: 32) {
                Spacer()

                // Icon / hero
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(glass)
                        .frame(width: 160, height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(glassStroke, lineWidth: 1)
                        )

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(primaryGreen, .yellow)
                }

                // Title
                Text("Welcome to Mawqit")
                    .font(.system(.largeTitle, design: .serif).bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                // Subtitle
                Text("Track today’s Hijri date, explore upcoming Islamic events, and get quick insights — all in one elegant, widget-first app.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Spacer()

                // Start button
                Button {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        didFinishOnboarding = true
                    }
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
