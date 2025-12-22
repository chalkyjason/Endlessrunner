import Foundation
import SpriteKit

/// LevelGenerator - Procedural generation using pattern chunks
/// Background actor for offloading heavy calculations from main thread
actor LevelGenerator {
    private var currentDifficulty: Difficulty = .easy
    private var lastChunkEnd: CGFloat = 0

    // MARK: - Pattern Chunk Definitions

    private let easyPatterns: [LevelChunk] = [
        LevelChunk(
            obstacles: [
                ObstacleData(type: .spike, relativeX: 2.0, y: 100)
            ],
            coins: [
                CoinData(relativeX: 1.0, y: 200)
            ],
            length: 400
        ),
        LevelChunk(
            obstacles: [
                ObstacleData(type: .block, relativeX: 1.5, y: 100)
            ],
            coins: [
                CoinData(relativeX: 0.5, y: 250),
                CoinData(relativeX: 2.5, y: 250)
            ],
            length: 500
        ),
        LevelChunk(
            obstacles: [
                ObstacleData(type: .spike, relativeX: 1.0, y: 100),
                ObstacleData(type: .spike, relativeX: 3.0, y: 100)
            ],
            coins: [
                CoinData(relativeX: 2.0, y: 220)
            ],
            length: 600
        )
    ]

    private let mediumPatterns: [LevelChunk] = [
        LevelChunk(
            obstacles: [
                ObstacleData(type: .spike, relativeX: 1.0, y: 100),
                ObstacleData(type: .block, relativeX: 2.5, y: 100),
                ObstacleData(type: .spike, relativeX: 4.0, y: 100)
            ],
            coins: [
                CoinData(relativeX: 1.75, y: 250),
                CoinData(relativeX: 3.25, y: 250)
            ],
            length: 650
        ),
        LevelChunk(
            obstacles: [
                ObstacleData(type: .triangle, relativeX: 1.5, y: 100),
                ObstacleData(type: .diamond, relativeX: 3.0, y: 200)
            ],
            coins: [
                CoinData(relativeX: 2.25, y: 150)
            ],
            length: 550
        )
    ]

    private let hardPatterns: [LevelChunk] = [
        LevelChunk(
            obstacles: [
                ObstacleData(type: .spike, relativeX: 0.8, y: 100),
                ObstacleData(type: .spike, relativeX: 1.6, y: 100),
                ObstacleData(type: .block, relativeX: 2.8, y: 100),
                ObstacleData(type: .diamond, relativeX: 4.2, y: 180)
            ],
            coins: [
                CoinData(relativeX: 1.2, y: 240),
                CoinData(relativeX: 2.2, y: 260),
                CoinData(relativeX: 3.5, y: 240)
            ],
            length: 700
        )
    ]

    // MARK: - Generation API

    func generateNextChunk(screenWidth: CGFloat, distance: Double) -> ChunkData {
        updateDifficulty(distance: distance)

        let patterns = getPatternPool()
        guard let selectedChunk = patterns.randomElement() else {
            return ChunkData(obstacles: [], coins: [], startX: lastChunkEnd, length: 500)
        }

        let startX = lastChunkEnd + screenWidth
        let absoluteObstacles = selectedChunk.obstacles.map { obstacle in
            ObstacleData(
                type: obstacle.type,
                relativeX: startX + (obstacle.relativeX * 100),  // Scale relative positions
                y: obstacle.y
            )
        }

        let absoluteCoins = selectedChunk.coins.map { coin in
            CoinData(
                relativeX: startX + (coin.relativeX * 100),
                y: coin.y
            )
        }

        lastChunkEnd = startX + selectedChunk.length

        return ChunkData(
            obstacles: absoluteObstacles,
            coins: absoluteCoins,
            startX: startX,
            length: selectedChunk.length
        )
    }

    func reset() {
        lastChunkEnd = 0
        currentDifficulty = .easy
    }

    // MARK: - Difficulty Scaling

    private func updateDifficulty(distance: Double) {
        if distance > 2000 {
            currentDifficulty = .hard
        } else if distance > 1000 {
            currentDifficulty = .medium
        } else {
            currentDifficulty = .easy
        }
    }

    private func getPatternPool() -> [LevelChunk] {
        switch currentDifficulty {
        case .easy:
            return easyPatterns
        case .medium:
            return easyPatterns + mediumPatterns
        case .hard:
            return mediumPatterns + hardPatterns
        }
    }
}

// MARK: - Data Structures

struct LevelChunk {
    let obstacles: [ObstacleData]
    let coins: [CoinData]
    let length: CGFloat
}

struct ObstacleData: Sendable {
    let type: ObstacleType
    let relativeX: CGFloat
    let y: CGFloat
}

struct CoinData: Sendable {
    let relativeX: CGFloat
    let y: CGFloat
}

struct ChunkData: Sendable {
    let obstacles: [ObstacleData]
    let coins: [CoinData]
    let startX: CGFloat
    let length: CGFloat
}

enum Difficulty {
    case easy
    case medium
    case hard
}

// Make ObstacleType Sendable for actor isolation
extension ObstacleType: Sendable {}
