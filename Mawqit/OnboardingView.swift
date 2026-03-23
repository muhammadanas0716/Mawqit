//
//  OnboardingView.swift
//  Mawqit
//
//  Forest redesign — 23 Mar 2026
//

import SwiftUI

private let primaryGreen = MawqitTheme.accentSun
private let accentBlue = MawqitTheme.accentSky
private let accentCoral = MawqitTheme.accentCoral
private let glass = MawqitTheme.card
private let raisedGlass = MawqitTheme.cardRaised
private let glassStroke = MawqitTheme.cardStroke
private let inkText = MawqitTheme.ink
private let accentInk = MawqitTheme.inkOnAccent

struct OnboardingView: View {
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false
    @AppStorage("userName") private var userName = ""
    @State private var nameInput = ""

    var body: some View {
        ZStack {
            MawqitSkyBackground()

            ScrollView {
                VStack(spacing: 20) {
                    heading
                    streakCard
                    featuresCard
                    nameCard
                    startButton
                    privacyCopy
                }
                .padding(.horizontal)
                .padding(.top, 28)
                .padding(.bottom, 16)
                .frame(maxWidth: 620)
            }
        }
        .onAppear {
            nameInput = userName
        }
    }

    private var heading: some View {
        VStack(spacing: 10) {
            Text("Night companion for prayer, Quran, and dhikr")
                .font(.caption.weight(.semibold))
                .foregroundColor(primaryGreen)
                .textCase(.uppercase)
                .tracking(2.2)

            Text("Build a daily relationship with the Qur'an")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundColor(inkText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("Small daily actions. Real consistency.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(MawqitTheme.mutedInk)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    private var streakCard: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.13, green: 0.24, blue: 0.18),
                                Color(red: 0.18, green: 0.35, blue: 0.26),
                                primaryGreen.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 210, height: 210)
                    .offset(y: -18)

                VStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 62, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("1")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))

                    Text("You just got your")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.88))

                    Text("FIRST STREAK")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            Text("Reach your goals and watch your hasanat grow.")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundColor(inkText)
                .padding(.horizontal, 6)
        }
        .padding(12)
        .mawqitCard(cornerRadius: 28)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .font(.headline)
                .foregroundColor(inkText)

            VStack(spacing: 10) {
                FeaturePill(icon: "book.closed.fill", title: "Hadith of the day", color: accentCoral)
                FeaturePill(icon: "clock.fill", title: "Accurate prayer times", color: accentBlue)
                FeaturePill(icon: "location.north.fill", title: "Live Qibla direction", color: primaryGreen)
                FeaturePill(icon: "bell.badge.fill", title: "Smart reminders", color: accentCoral)
                FeaturePill(icon: "circle.grid.cross.fill", title: "Dhikr streak tracking", color: accentBlue)
            }
        }
        .padding()
        .mawqitCard(cornerRadius: 22)
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What should we call you?")
                .font(.headline)
                .foregroundColor(inkText)

            TextField("Your name (optional)", text: $nameInput)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MawqitTheme.inputFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(glassStroke, lineWidth: 1)
                )
                .foregroundColor(inkText)
                .tint(primaryGreen)

            Text("This stays on your device.")
                .font(.caption)
                .foregroundColor(MawqitTheme.mutedInk)
        }
        .padding()
        .mawqitCard(cornerRadius: 22)
    }

    private var startButton: some View {
        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                userName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                didFinishOnboarding = true
            }
        } label: {
            Text("Start Your Journey")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primaryGreen)
                .foregroundColor(accentInk)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: MawqitTheme.cardShadow, radius: 12, x: 0, y: 8)
        }
    }

    private var privacyCopy: some View {
        Text("No account required. Your data stays on device.")
            .font(.caption)
            .foregroundColor(MawqitTheme.mutedInk)
            .multilineTextAlignment(.center)
            .padding(.bottom, 8)
    }
}

private struct FeaturePill: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(inkText)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(raisedGlass, in: Capsule())
        .overlay(
            Capsule()
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}
