import SwiftUI

enum AppRoute: Hashable {
    case settings
    case scoreBoard
}

// Main menu screen of the app
// From here, the user can start a new game or view the score board
struct ContentView: View {
   
    // Shared game data
    @EnvironmentObject var gameViewModel: GameViewModel
   
    // Navigation path
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                ZStack {
                   
                    // Background image
                    Image("HomeBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(1.1)
                        .offset(y: 60)
                        .clipped()
                        .ignoresSafeArea()

                    VStack {
                        Spacer()

                        // Main menu card
                        VStack(spacing: 18) {
                            Text("Pop bubbles and earn points!")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("Tap bubbles before they fall off the screen.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            // New Game button
                            Button {
                                gameViewModel.resetSettingsForNewGame()
                                path.append(.settings)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                    Text("New Game")
                                        .fontWeight(.bold)
                                }
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(18)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }

                            // Score Board button
                            NavigationLink(value: AppRoute.scoreBoard) {
                                HStack(spacing: 10) {
                                    Image(systemName: "list.number")
                                    Text("Score Board")
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
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 16))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .toolbar(.hidden, for: .navigationBar)

            // Navigation destinations
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView {
                        path.removeAll()
                    }

                case .scoreBoard:
                    HighScoreView()
                }
            }
        }
    }
}

// Preview for Xcode canvas
#Preview {
    ContentView()
        .environmentObject(GameViewModel())
}
