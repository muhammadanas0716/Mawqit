//
//  OnboardingView.swift
//  Mawqit
//
//  Dark-theme – 14 Jul 2025
//

import SwiftUI

// Same palette used in ContentView
private let primaryGreen   = Color(red: 0.10, green: 0.55, blue: 0.44)   // #198C71
private let accentGold     = Color(red: 0.90, green: 0.74, blue: 0.36)
private let glass          = Color.white.opacity(0.06)
private let glassStroke    = Color.white.opacity(0.12)
private let deepBlack      = Color(red: 0.02, green: 0.02, blue: 0.03)

struct OnboardingView: View {
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false
    @AppStorage("userName") private var userName = ""
    @State private var nameInput = ""

    var body: some View {
        ZStack {
            deepBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(glass)
                                .frame(width: 150, height: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .stroke(glassStroke, lineWidth: 1)
                                )

                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(primaryGreen, accentGold)
                        }

                        Text("Mawqit")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .foregroundColor(.white)

                        Text("Your daily Muslim companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("A calm, focused home for your day")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)

                        Text("Stay aligned with daily hadith, reminders, and dhikr, plus widgets and notifications that keep your rhythm steady.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(glass, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )

                    VStack(spacing: 14) {
                        FeatureRow(icon: "book.closed", title: "Hadith of the Day",
                                   subtitle: "Fresh inspiration from Riyad as-Salihin.")
                        FeatureRow(icon: "clock", title: "Prayer Times",
                                   subtitle: "Accurate timings based on your location.")
                        FeatureRow(icon: "location.north", title: "Qibla Compass",
                                   subtitle: "Find the direction to the Kaaba.")
                        FeatureRow(icon: "bell.badge", title: "Smart Reminders",
                                   subtitle: "Set daily and Jumu'ah alerts.")
                        FeatureRow(icon: "circle.grid.cross", title: "Dhikr Counter",
                                   subtitle: "Track and reset with haptics.")
                        FeatureRow(icon: "rectangle.stack.badge.plus", title: "Beautiful Widgets",
                                   subtitle: "Hijri date and daily inspiration.")
                    }
                    .padding()
                    .background(glass, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What should we call you?")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Your name (optional)", text: $nameInput)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(glass, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(glassStroke, lineWidth: 1)
                            )
                            .foregroundColor(.white)

                        Text("This stays on your device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            userName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            didFinishOnboarding = true
                        }
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryGreen)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text("No account required. Your data stays on device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .frame(maxWidth: 620)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            nameInput = userName
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(primaryGreen.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(primaryGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}
