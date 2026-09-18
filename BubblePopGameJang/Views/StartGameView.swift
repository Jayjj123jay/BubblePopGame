import SwiftUI

// Main game screen where bubbles appear and user plays the game
struct StartGameView: View {
    
    // Shared ViewModel (handles game logic and data)
    @EnvironmentObject var gameViewModel: GameViewModel
    
    let onHome: () -> Void

    @State private var showHighScoreSheet = false
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            
            // Background gradient
            LinearGradient(
                colors: [.white, .cyan.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                
                // Top info (player, time, score)
                headerView

                // This GeometryReader gets the real size of the game area
                GeometryReader { gameArea in
                    ZStack {
                        // Game area background
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.gray.opacity(0.08))

                        // Display all bubbles
                        ForEach(gameViewModel.bubbles) { bubble in
                            BubbleCircleView(bubble: bubble)
                                .position(x: bubble.x, y: bubble.y)
                                .onTapGesture {
                                    // Pop bubble when tapped
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        gameViewModel.popBubble(bubble)
                                    }
                                }
                        }

                        // Combo message animation
                        if gameViewModel.showCombo {
                            ComboMessageView(message: gameViewModel.comboMessage)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Countdown before game starts
                        if gameViewModel.isShowingCountdown {
                            CountdownOverlayView(text: gameViewModel.countdownText)
                                .id(gameViewModel.countdownStep)
                        }

                        // Game over screen
                        if gameViewModel.isGameOver {
                            GameOverOverlayView(score: gameViewModel.score)
                        }
                    }
                    .onAppear {
                        gameViewModel.configureGameArea(gameArea.size)

                        if !gameStarted {
                            gameStarted = true
                            gameViewModel.startGame(in: gameArea.size)
                        }
                    }
                    .onChange(of: gameArea.size) { _, newSize in
                        gameViewModel.configureGameArea(newSize)
                    }
                    .clipped()
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: gameViewModel.isGameOver) { _, isOver in
            if isOver {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showHighScoreSheet = true
                }
            }
        }
        .sheet(isPresented: $showHighScoreSheet) {
            NavigationStack {
                HighScoreView(
                    latestPlayerName: gameViewModel.playerName,
                    latestScore: gameViewModel.score,
                    onHome: {
                        showHighScoreSheet = false
                        onHome()
                    }
                )
                .environmentObject(gameViewModel)
            }
        }
    }

    // Top UI showing player name, time, score, and high score
    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                StatBox(
                    title: "Player",
                    value: gameViewModel.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Player"
                        : gameViewModel.playerName
                )

                StatBox(title: "Time", value: "\(gameViewModel.timeRemaining)")
            }

            HStack {
                StatBox(title: "Score", value: "\(gameViewModel.score)")
                StatBox(title: "High Score", value: "\(gameViewModel.highestScore)")
            }
        }
    }
}

// View for each bubble
struct BubbleCircleView: View {
    let bubble: Bubble

    var body: some View {
        ZStack {
            // Main bubble color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            bubble.colorType.color.opacity(0.35),
                            bubble.colorType.color,
                            bubble.colorType.color.opacity(0.95)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: bubble.size / 2
                    )
                )

            // Soft highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(bubble.size * 0.08)

            // Small glossy shine near the top
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: bubble.size * 0.23, height: bubble.size * 0.23)
                .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.18)

            // Outer border
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)

            // Inner soft border
            Circle()
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                .padding(3)
        }
        .frame(width: bubble.size, height: bubble.size)
        .shadow(color: bubble.colorType.color.opacity(0.35), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
        .scaleEffect(bubble.isPopping ? 0.15 : 1.0)
        .opacity(bubble.isPopping ? 0.0 : 1.0)
        .rotationEffect(.degrees(bubble.isPopping ? 20 : 0))
        .animation(.easeOut(duration: 0.18), value: bubble.isPopping)
    }
}

// Combo text shown after popping bubbles
struct ComboMessageView: View {
    let message: String
    @State private var yOffset: CGFloat = 20
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack {
            Text(message)
                .font(.headline.bold())
                .foregroundStyle(.purple)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .offset(y: yOffset)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.15)) {
                        opacity = 1.0
                        yOffset = 0
                    }

                    withAnimation(.easeIn(duration: 0.45).delay(0.1)) {
                        opacity = 0.0
                        yOffset = -35
                    }
                }

            Spacer()
        }
        .padding(.top, 16)
    }
}

// Countdown shown before the game begins
struct CountdownOverlayView: View {
    let text: String

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            Text(text)
                .font(.system(size: text == "Game Start!" ? 38 : 72, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    scale = 0.5
                    opacity = 0.0

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        scale = 1.15
                        opacity = 1.0
                    }

                    withAnimation(.easeOut(duration: 0.25).delay(0.7)) {
                        scale = 0.9
                        opacity = 0.0
                    }
                }
        }
    }
}

// Game over overlay
struct GameOverOverlayView: View {
    let score: Int
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Game Over")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final Score: \(score)")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color.red.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// Small box for player, time, score, etc.
struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.88))
        .cornerRadius(14)
        .shadow(radius: 1)
    }
}

#Preview {
    NavigationStack {
        StartGameView(onHome: { })
            .environmentObject(GameViewModel())
    }
}
