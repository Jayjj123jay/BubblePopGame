import Foundation

// Struct to store each player's score
// Includes player name and their score
struct ScoreEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    let playerName: String
    let score: Int
}