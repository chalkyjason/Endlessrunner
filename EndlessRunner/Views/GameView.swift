import SwiftUI
import SpriteKit

/// GameView - Hybrid SwiftUI/SpriteKit architecture
/// Layer 1: SpriteKit game engine
/// Layer 2: SwiftUI HUD overlay
struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var gameScene: GameScene?

    var body: some View {
        ZStack {
            // Layer 1: SpriteKit Game Engine
            SpriteKitContainer(scene: $gameScene, gameManager: gameManager)
                .ignoresSafeArea()

            // Layer 2: SwiftUI HUD (Declarative UI)
            VStack {
                HUDView()
                Spacer()
            }
            .padding()

            // Pause overlay
            if gameManager.isPaused {
                PauseOverlay()
            }
        }
        .onAppear {
            // Scene initialization happens in SpriteKitContainer
        }
    }
}

// MARK: - SpriteKit Container (Wrapper)

struct SpriteKitContainer: UIViewRepresentable {
    @Binding var scene: GameScene?
    let gameManager: GameManager

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true  // Debug info
        skView.showsNodeCount = true

        // Optimization settings
        skView.preferredFramesPerSecond = 60
        skView.isAsynchronous = true

        // Create and present scene
        let newScene = GameScene(size: UIScreen.main.bounds.size, gameManager: gameManager)
        newScene.scaleMode = .aspectFill
        skView.presentScene(newScene)

        // Bind scene to state
        DispatchQueue.main.async {
            scene = newScene
        }

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Handle scene updates if needed
    }
}

// MARK: - HUD View

struct HUDView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                // Score
                HStack(spacing: 8) {
                    Text("SCORE")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(gameManager.score)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Distance
                HStack(spacing: 8) {
                    Text("DISTANCE")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f m", gameManager.distance))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Health
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < gameManager.health ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)

            Spacer()

            // Pause button
            Button(action: {
                gameManager.pauseGame()
            }) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Pause Overlay

struct PauseOverlay: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("PAUSED")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Button(action: {
                    gameManager.resumeGame()
                }) {
                    Text("RESUME")
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 60)
                        .background(Color.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    gameManager.returnToMenu()
                }) {
                    Text("QUIT")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
    }
}
