// SetupView.swift
//
// The first screen the user sees. It collects two pieces of information:
//
// 1. **Server URL** — the address of the companion server that creates journey sessions.
//    Defaults to http://localhost:3000 (works in the Simulator; use your Mac's IP for device).
//
// 2. **Resource ID** — identifies which journey template to run. The format is <id>@<version>.
//    Use @latest to always get the current version.
//
// When the user taps "Start Journey", the app calls the companion server to create a session
// and receive a journey URL. See JourneyService.swift for the network call.

import SwiftUI

struct SetupView: View {
    let onJourneyStarted: (URL) -> Void

    // Persisted between launches so the user doesn't have to re-enter them.
    @AppStorage("serverURL") private var serverURL = "http://localhost:3000"
    @AppStorage("resourceId") private var resourceId = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Configure the companion server connection and journey template, then tap Start Journey to begin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Companion Server") {
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Text("The companion server creates journey sessions using the GBG Go Core SDK. See server/README.md for setup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Journey Template") {
                TextField("Resource ID (optional)", text: $resourceId)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text("Leave blank to use the server's default. Format: <id>@<version> (e.g. abc123@latest).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            Section {
                Button(action: startJourney) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Start Journey")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isLoading || serverURL.isEmpty)
            }
        }
        .navigationTitle("GBG Go Reference")
    }

    private func startJourney() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await JourneyService.startJourney(
                    serverURL: serverURL,
                    resourceId: resourceId.isEmpty ? nil : resourceId
                )
                onJourneyStarted(response.journeyUrl)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
