// RootView.swift
//
// The navigation root. Uses NavigationStack (iOS 16+) to switch between:
// 1. SetupView — where the user configures the server URL and starts a journey
// 2. JourneyView — where the journey runs inside a BridgeWebView
//
// The journey URL is obtained from the companion server at runtime.
// See JourneyService.swift for how that call is made.

import SwiftUI

struct RootView: View {
    /// Navigation path controls the stack programmatically.
    @State private var navigationPath = NavigationPath()
    /// Holds the journey URL after a successful server call.
    @State private var journeyURL: URL?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SetupView(onJourneyStarted: { url in
                journeyURL = url
                navigationPath.append("journey")
            })
            .navigationDestination(for: String.self) { route in
                if route == "journey", let url = journeyURL {
                    JourneyView(journeyURL: url)
                }
            }
        }
    }
}
