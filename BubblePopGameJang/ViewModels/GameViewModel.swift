import Foundation
import SwiftUI
import Combine

// This ViewModel manages game data such as player name, score, bubbles, and high scores
final class GameViewModel: ObservableObject {
    
    // Player settings
    @Published var playerName: String = ""
    @Published var gameTime: Double = 60
    @Published var maxBubbles: Double = 15

    // Current game state
    @Published var bubbles: [Bubble] = []
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 60
    @Published var isGameOver: Bool = false
    @Published var comboMessage: String = ""
    @Published var showCombo: Bool = false

    // Countdown animation before the game starts
    @Published var countdownText: String = ""
    @Published var countdownStep: Int = 0
    @Published var isShowingCountdown: Bool = true
    @Published var gameHasStarted: Bool = false

    // High score list
    @Published var highScores: [ScoreEntry] = []

    private let saveKey = "bubble_pop_high_scores"

    private var gameTimer: Timer?
    private var fallTimer: Timer?
    private var countdownTimer: Timer?
    private var playAreaSize: CGSize = .zero
    private var lastPoppedColor: BubbleColorType?
    private var currentTargetBubbleCount: Int = 0

    // Use one base speed so bubbles do not catch each other and overlap
    private let baseFallSpeed: CGFloat = 2.0

    init() {
        loadScores()
    }

    // Return the highest score from the saved list
    var highestScore: Int {
        highScores.first?.score ?? 0
    }

    // Save the current game area size
    func configureGameArea(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let oldSize = playAreaSize
        playAreaSize = size

        // If screen size changes during gameplay, regenerate bubbles safely
        if oldSize != .zero, oldSize != size, !isGameOver {
            repositionBubblesForNewSize()
        }
    }

    // Reset values before starting a new game
    func resetGame() {
        gameTimer?.invalidate()
        fallTimer?.invalidate()
        countdownTimer?.invalidate()

        gameTimer = nil
        fallTimer = nil
        countdownTimer = nil

        score = 0
        timeRemaining = min(max(Int(gameTime), 5), 60)
        isGameOver = false
        comboMessage = ""
        showCombo = false
        lastPoppedColor = nil
        bubbles.removeAll()

        countdownText = ""
        countdownStep = 0
        isShowingCountdown = true
        gameHasStarted = false
        currentTargetBubbleCount = Int.random(in: 1...max(1, Int(maxBubbles)))
    }

    // Reset settings to default values when starting a new game setup
    func resetSettingsForNewGame() {
        playerName = ""
        gameTime = 60
        maxBubbles = 15
    }

    // Start a new game
    func startGame(in size: CGSize) {
        configureGameArea(size)
        resetGame()
        generateInitialBubbles()
        startCountdownSequence()
    }

    // Stop timers and end the game
    func stopGame() {
        gameTimer?.invalidate()
        fallTimer?.invalidate()
        countdownTimer?.invalidate()

        gameTimer = nil
        fallTimer = nil
        countdownTimer = nil

        isGameOver = true
    }

    deinit {
        gameTimer?.invalidate()
        fallTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    // Countdown animation before gameplay
    private func startCountdownSequence() {
        countdownTimer?.invalidate()

        let sequence = ["3", "2", "1", "Game Start!"]
        var index = 0

        countdownText = sequence[index]
        countdownStep += 1
        isShowingCountdown = true
        gameHasStarted = false

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            index += 1

            if index < sequence.count {
                self.countdownText = sequence[index]
                self.countdownStep += 1
            } else {
                timer.invalidate()
                self.countdownTimer = nil

                self.isShowingCountdown = false
                self.gameHasStarted = true
                self.startTimers()
            }
        }

        countdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // Start game timer and falling animation timer
    private func startTimers() {
        gameTimer?.invalidate()
        fallTimer?.invalidate()

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.gameTick()
        }

        fallTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateBubbleFalling()
        }
    }

    // Runs once every second
    private func gameTick() {
        guard !isGameOver, gameHasStarted else { return }

        timeRemaining -= 1

        if timeRemaining <= 0 {
            timeRemaining = 0
            saveCurrentScore()
            stopGame()
            return
        }

        refreshBubblesEverySecond()
    }

    // Move bubbles downward over time
    private func updateBubbleFalling() {
        guard !isGameOver, gameHasStarted else { return }
        guard playAreaSize.width > 0, playAreaSize.height > 0 else { return }

        let difficultyFactor = 1.0 + CGFloat((60 - min(timeRemaining, 60))) / 60.0

        for index in bubbles.indices {
            bubbles[index].y += baseFallSpeed * difficultyFactor
        }

        // Remove bubbles only after they fully leave the bottom of the screen
        bubbles.removeAll { bubble in
            bubble.y - bubble.size / 2 > playAreaSize.height + 30
        }

        refillIfNeeded()
    }

    // Handle bubble tap
    func popBubble(_ bubble: Bubble) {
        guard !isGameOver, gameHasStarted else { return }
        guard let index = bubbles.firstIndex(of: bubble) else { return }
        guard bubbles[index].isPopping == false else { return }

        let poppedBubble = bubbles[index]
        bubbles[index].isPopping = true

        let basePoints = poppedBubble.colorType.points
        let awardedPoints: Int

        // If same color is popped consecutively, apply combo bonus
        if lastPoppedColor == poppedBubble.colorType {
            awardedPoints = Int((Double(basePoints) * 1.5).rounded())
            comboMessage = "Combo! +\(awardedPoints)"
        } else {
            awardedPoints = basePoints
            comboMessage = "+\(awardedPoints)"
        }

        score += awardedPoints
        lastPoppedColor = poppedBubble.colorType

        showTemporaryCombo()
        removeBubbleAfterAnimation(bubbleID: poppedBubble.id)
    }

    // Show combo text briefly
    private func showTemporaryCombo() {
        showCombo = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.showCombo = false
        }
    }

    // Remove a bubble after the pop animation finishes
    private func removeBubbleAfterAnimation(bubbleID: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.bubbles.removeAll { $0.id == bubbleID }
            self?.refillIfNeeded()
        }
    }

    // Create the initial set of bubbles
    private func generateInitialBubbles() {
        currentTargetBubbleCount = Int.random(in: 1...max(1, Int(maxBubbles)))
        bubbles = generateNonOverlappingBubbles(targetCount: currentTargetBubbleCount, existing: [])
    }

    // Refresh bubbles every game second
    private func refreshBubblesEverySecond() {
        guard !bubbles.isEmpty else {
            currentTargetBubbleCount = Int.random(in: 0...max(1, Int(maxBubbles)))
            refillIfNeeded()
            return
        }

        // Only remove bubbles that are still on screen and not popping
        let removableBubbles = bubbles.filter { !$0.isPopping }

        if !removableBubbles.isEmpty {
            let removeCount = Int.random(in: 0...removableBubbles.count)
            let removeIDs = Array(removableBubbles.shuffled().prefix(removeCount)).map { $0.id }

            bubbles.removeAll { bubble in
                removeIDs.contains(bubble.id)
            }
        }

        // Randomly decide how many bubbles should be shown after refresh
        currentTargetBubbleCount = Int.random(in: 0...max(1, Int(maxBubbles)))

        refillIfNeeded()
    }

    // Refill bubbles until the current target count is reached
    private func refillIfNeeded() {
        let activeBubbleCount = bubbles.filter { !$0.isPopping }.count
        let needToAdd = max(0, currentTargetBubbleCount - activeBubbleCount)

        guard needToAdd > 0 else { return }

        let newBubbles = generateNonOverlappingBubbles(targetCount: needToAdd, existing: bubbles)
        bubbles.append(contentsOf: newBubbles)
    }

    // Re-create bubbles when screen size changes
    private func repositionBubblesForNewSize() {
        let activeCount = min(bubbles.filter { !$0.isPopping }.count, max(1, Int(maxBubbles)))
        currentTargetBubbleCount = max(1, activeCount)
        bubbles = generateNonOverlappingBubbles(targetCount: currentTargetBubbleCount, existing: [])
    }

    // Generate bubbles in random positions without overlapping
    private func generateNonOverlappingBubbles(targetCount: Int, existing: [Bubble]) -> [Bubble] {
        guard playAreaSize.width > 0, playAreaSize.height > 0 else { return [] }

        var result: [Bubble] = []
        var occupied = existing

        let bubbleSize = max(50, min(playAreaSize.width, playAreaSize.height) * 0.11)
        let safeSpacing: CGFloat = 14
        let maxAttemptsPerBubble = 120

        for _ in 0..<targetCount {
            var attempts = 0
            var createdBubble: Bubble?

            while attempts < maxAttemptsPerBubble && createdBubble == nil {
                attempts += 1

                let radius = bubbleSize / 2
                let x = CGFloat.random(in: radius...(playAreaSize.width - radius))
                let y = CGFloat.random(in: (-180)...(radius + 10))

                let candidate = Bubble(
                    colorType: randomBubbleColor(),
                    size: bubbleSize,
                    x: x,
                    y: y,
                    fallSpeed: baseFallSpeed,
                    isPopping: false
                )

                let overlaps = occupied.contains { bubble in
                    let dx = candidate.x - bubble.x
                    let dy = candidate.y - bubble.y
                    let distance = sqrt(dx * dx + dy * dy)
                    return distance < ((candidate.size + bubble.size) / 2 + safeSpacing)
                }

                if !overlaps {
                    createdBubble = candidate
                }
            }

            if let bubble = createdBubble {
                result.append(bubble)
                occupied.append(bubble)
            }
        }

        return result
    }

    // Choose a random color using probability weights
    private func randomBubbleColor() -> BubbleColorType {
        let totalWeight = BubbleColorType.allCases.reduce(0) { $0 + $1.probabilityWeight }
        let randomValue = Int.random(in: 1...totalWeight)

        var runningWeight = 0
        for color in BubbleColorType.allCases {
            runningWeight += color.probabilityWeight
            if randomValue <= runningWeight {
                return color
            }
        }

        return .red
    }

    // Save the current score
    private func saveCurrentScore() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "Player" : trimmedName

        if let index = highScores.firstIndex(where: { $0.playerName == finalName }) {
            if score > highScores[index].score {
                highScores[index] = ScoreEntry(playerName: finalName, score: score)
            }
        } else {
            highScores.append(ScoreEntry(playerName: finalName, score: score))
        }

        highScores.sort { $0.score > $1.score }
        persistScores()
    }

    // Save score data to UserDefaults
    private func persistScores() {
        if let data = try? JSONEncoder().encode(highScores) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    // Load saved score data
    private func loadScores() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            highScores = decoded.sorted { $0.score > $1.score }
        } else {
            highScores = []
        }
    }
}
