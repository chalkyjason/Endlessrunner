import SwiftUI
import Combine

/// External State Manager - The "truth" of game state
/// Conforms to ObservableObject for reactive SwiftUI updates
@MainActor
class GameManager: ObservableObject {
    // MARK: - Published Properties (Trigger SwiftUI Updates)

    @Published var score: Int = 0
    @Published var distance: Double = 0.0
    @Published var gameState: GameState = .menu
    @Published var health: Int = 3
    @Published var isPaused: Bool = false

    // MARK: - Game Configuration

    let baseSpeed: CGFloat = 300.0  // Points per second
    var currentSpeed: CGFloat = 300.0
    let speedIncreaseRate: CGFloat = 5.0  // Increase per second
    let maxSpeed: CGFloat = 600.0

    // MARK: - Input State (Sampled by InputComponent)

    var isJumpPressed: Bool = false
    var isSlidePressed: Bool = false

    // MARK: - Game Control Methods

    func startGame() {
        score = 0
        distance = 0.0
        health = 3
        currentSpeed = baseSpeed
        gameState = .playing
        isPaused = false
    }

    func pauseGame() {
        isPaused = true
    }

    func resumeGame() {
        isPaused = false
    }

    func gameOver() {
        gameState = .gameOver
    }

    func returnToMenu() {
        gameState = .menu
    }

    // MARK: - Score Management

    func addScore(_ points: Int) {
        score += points
    }

    func updateDistance(_ delta: Double) {
        distance += delta
    }

    func updateSpeed(_ deltaTime: TimeInterval) {
        currentSpeed = min(currentSpeed + speedIncreaseRate * CGFloat(deltaTime), maxSpeed)
    }

    // MARK: - Health Management

    func takeDamage() {
        health -= 1
        if health <= 0 {
            gameOver()
        }
    }

    func heal() {
        health = min(health + 1, 3)
    }
}

// MARK: - Game State Enum

enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}
