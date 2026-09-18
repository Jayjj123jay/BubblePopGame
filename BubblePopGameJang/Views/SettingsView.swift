import SwiftUI

// Settings screen where player can enter name and adjust game options
struct SettingsView: View {
    
    // Access shared ViewModel
    @EnvironmentObject var gameViewModel: GameViewModel

    let onHome: () -> Void

    @State private var showNameAlert = false
    @State private var goToGame = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background color
            LinearGradient(
                colors: [.white, .mint.opacity(0.08), .cyan.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // Title area
                    VStack(spacing: 8) {
                        Text("Game Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)

                        Text("Set your name and game options before starting.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Name input box
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Player Name", systemImage: "person.fill")
                            .font(.headline)

                        TextField("Enter your name", text: $gameViewModel.playerName)
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.25), lineWidth: 1)
                            )
                            .cornerRadius(16)
                            .focused($isNameFieldFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    }
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                    // Game time box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Game Time", systemImage: "clock.fill")
                                .font(.headline)

                            Spacer()

                            Text("\(Int(gameViewModel.gameTime)) sec")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }

                        Slider(value: $gameViewModel.gameTime, in: 5...60, step: 1)

                        Text("Set a valid game time between 5 and 60 seconds.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                    // Max bubble box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Max Number of Bubbles", systemImage: "circle.grid.3x3.fill")
                                .font(.headline)

                            Spacer()

                            Text("\(Int(gameViewModel.maxBubbles))")
                                .font(.headline)
                                .foregroundStyle(.pink)
                        }

                        Slider(value: $gameViewModel.maxBubbles, in: 5...15, step: 1)

                        Text("Set the maximum number of bubbles between 5 and 15.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                    // Start button
                    Button {
                        let trimmedName = gameViewModel.playerName.trimmingCharacters(in: .whitespacesAndNewlines)

                        if trimmedName.isEmpty {
                            showNameAlert = true
                        } else {
                            gameViewModel.playerName = trimmedName
                            isNameFieldFocused = false
                            goToGame = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("Game Start")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 5)
                    }
                    .padding(.top, 4)

                    // Hidden navigation link
                    NavigationLink(
                        destination: StartGameView(
                            onHome: {
                                onHome()
                            }
                        ),
                        isActive: $goToGame
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)

        .onAppear {
            gameViewModel.playerName = ""
            gameViewModel.gameTime = 60
            gameViewModel.maxBubbles = 15
        }

        .alert("Error", isPresented: $showNameAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please Input Palyer's Name")
        }
    }
}

// Preview for testing UI in Xcode
#Preview {
    NavigationStack {
        SettingsView(onHome: { })
            .environmentObject(GameViewModel())
    }
}