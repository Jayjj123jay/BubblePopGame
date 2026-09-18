import SwiftUI

// Screen for showing saved high scores
struct HighScoreView: View {
    @EnvironmentObject var gameViewModel: GameViewModel

    var latestPlayerName: String? = nil
    var latestScore: Int? = nil
    var onHome: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("Score Board")
                .font(.largeTitle.bold())
                .foregroundStyle(.orange)

            if let latestPlayerName, let latestScore {
                VStack(spacing: 6) {
                    Text("Latest Result")
                        .font(.headline)

                    Text("\(latestPlayerName.isEmpty ? "Player" : latestPlayerName): \(latestScore)")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
            }

            if gameViewModel.highScores.isEmpty {
                Spacer()
                Text("No scores yet.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(gameViewModel.highScores.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("#\(index + 1)")
                                .frame(width: 45, alignment: .leading)
                                .font(.headline)

                            Text(entry.playerName)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(entry.score)")
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }

            if let onHome {
                Button {
                    onHome()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "house.fill")
                        Text("Home")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HighScoreView(latestPlayerName: "Player", latestScore: 100, onHome: { })
            .environmentObject(GameViewModel())
    }
}