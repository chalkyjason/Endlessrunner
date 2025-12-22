import SwiftUI

/// ContentView - Root view managing game state routing
struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameManager.gameState {
            case .menu:
                MenuView()
            case .playing, .paused:
                GameView()
            case .gameOver:
                GameOverView()
            }
        }
    }
}

// MARK: - Menu View

struct MenuView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 40) {
            Text("ENDLESS RUNNER")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text("Shape-Based Architecture")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)

            VStack(spacing: 20) {
                Button(action: {
                    gameManager.startGame()
                }) {
                    Text("START GAME")
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 250, height: 60)
                        .background(Color.white)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("CONTROLS:")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)

                    Text("• Tap to Jump")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))

                    Text("• Avoid Obstacles")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))

                    Text("• Collect Coins")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Game Over View

struct GameOverView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 30) {
            Text("GAME OVER")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.red)

            VStack(spacing: 16) {
                ScoreDisplayRow(label: "FINAL SCORE", value: String(gameManager.score))
                ScoreDisplayRow(label: "DISTANCE", value: String(format: "%.0f m", gameManager.distance))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            HStack(spacing: 20) {
                Button(action: {
                    gameManager.startGame()
                }) {
                    Text("RETRY")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 140, height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    gameManager.returnToMenu()
                }) {
                    Text("MENU")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct ScoreDisplayRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
