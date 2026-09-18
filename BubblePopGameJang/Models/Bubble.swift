import SwiftUI

// Enum for different bubble colors
// Each color has its own score and probability
enum BubbleColorType: String, CaseIterable, Codable {
    case red
    case pink
    case green
    case blue
    case black

    // Return score based on bubble color
    var points: Int {
        switch self {
        case .red: return 1
        case .pink: return 2
        case .green: return 5
        case .blue: return 8
        case .black: return 10
        }
    }

    // Probability weight for each color
    // Higher number means it appears more often
    var probabilityWeight: Int {
        switch self {
        case .red: return 40
        case .pink: return 30
        case .green: return 15
        case .blue: return 10
        case .black: return 5
        }
    }

    // Color used for display on screen
    var color: Color {
        switch self {
        case .red:
            return .red
        
        case .pink:
            // Bright pink so it is clearly different from red
            return Color(red: 1.0, green: 0.35, blue: 0.75)
        
        case .green:
            return .green
        
        case .blue:
            return .blue
        
        case .black:
            return Color(red: 0.15, green: 0.15, blue: 0.18)
        }
    }
}

// Struct representing a single bubble in the game
struct Bubble: Identifiable, Equatable {
    let id = UUID()
    let colorType: BubbleColorType
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var fallSpeed: CGFloat
    var isPopping: Bool = false
}