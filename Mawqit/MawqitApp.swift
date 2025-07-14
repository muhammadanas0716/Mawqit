//
//  MawqitApp.swift
//  Mawqit
//
//  Created by Muhammad Anas on 14/07/2025.
//

import SwiftUI

@main
struct MawqitApp: App {
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didFinishOnboarding {
                    ContentView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.05)),
                            removal: .opacity
                        ))
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            // Ensures animation applies on first flag change
            .animation(.easeInOut(duration: 0.45), value: didFinishOnboarding)
        }
    }
}
